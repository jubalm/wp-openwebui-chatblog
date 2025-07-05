"""
Multi-Tenant Management API
Provides programmatic access to tenant management operations
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum
import uuid
import subprocess
import os
import httpx
import yaml
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TenantTier(str, Enum):
    FREE = "free"
    PRO = "pro"
    ENTERPRISE = "enterprise"

class TenantStatus(str, Enum):
    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    DELETED = "deleted"

@dataclass
class TenantFeatures:
    content_automation: bool = True
    sso_enabled: bool = False
    custom_plugins: bool = False
    analytics_enabled: bool = False
    backup_enabled: bool = False

@dataclass
class TenantResources:
    cpu_request: str = "100m"
    cpu_limit: str = "500m"
    memory_request: str = "128Mi"
    memory_limit: str = "512Mi"
    storage_size: str = "5Gi"
    db_cores: int = 1
    db_ram: int = 2
    db_storage: int = 10

@dataclass
class TenantSettings:
    timezone: str = "UTC"
    language: str = "en_US"
    theme: str = "twentytwentyfour"
    auto_updates_enabled: bool = True
    debug_mode: bool = False

@dataclass
class Tenant:
    id: str
    display_name: str
    admin_email: str
    admin_user: str
    admin_password: str
    tier: TenantTier
    status: TenantStatus
    features: TenantFeatures
    resources: TenantResources
    settings: TenantSettings
    custom_domains: List[str]
    created_at: datetime
    updated_at: datetime
    region: str = "de/txl"
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "display_name": self.display_name,
            "admin_email": self.admin_email,
            "admin_user": self.admin_user,
            "tier": self.tier.value,
            "status": self.status.value,
            "features": asdict(self.features),
            "resources": asdict(self.resources),
            "settings": asdict(self.settings),
            "custom_domains": self.custom_domains,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "region": self.region
        }

@dataclass
class TenantUsageMetrics:
    tenant_id: str
    cpu_usage_hours: float
    memory_usage_gb_hours: float
    storage_usage_gb_hours: float
    api_requests: int
    content_workflows: int
    database_queries: int
    bandwidth_gb: float
    period_start: datetime
    period_end: datetime

class TenantManager:
    """Multi-tenant management service"""
    
    def __init__(self, project_root: str = None):
        self.project_root = Path(project_root or os.getcwd())
        self.terraform_dir = self.project_root / "terraform" / "tenant"
        self.kubeconfig_path = self.project_root / "kubeconfig.yaml"
        
        # Tier configurations
        self.tier_configs = {
            TenantTier.FREE: TenantResources(
                cpu_request="100m",
                cpu_limit="500m",
                memory_request="128Mi",
                memory_limit="512Mi",
                storage_size="5Gi",
                db_cores=1,
                db_ram=2,
                db_storage=10
            ),
            TenantTier.PRO: TenantResources(
                cpu_request="250m",
                cpu_limit="2000m",
                memory_request="256Mi",
                memory_limit="2Gi",
                storage_size="50Gi",
                db_cores=2,
                db_ram=4,
                db_storage=50
            ),
            TenantTier.ENTERPRISE: TenantResources(
                cpu_request="500m",
                cpu_limit="4000m",
                memory_request="512Mi",
                memory_limit="4Gi",
                storage_size="200Gi",
                db_cores=4,
                db_ram=8,
                db_storage=200
            )
        }
        
        self.tier_features = {
            TenantTier.FREE: TenantFeatures(
                content_automation=True,
                sso_enabled=False,
                custom_plugins=False,
                analytics_enabled=False,
                backup_enabled=False
            ),
            TenantTier.PRO: TenantFeatures(
                content_automation=True,
                sso_enabled=True,
                custom_plugins=True,
                analytics_enabled=True,
                backup_enabled=True
            ),
            TenantTier.ENTERPRISE: TenantFeatures(
                content_automation=True,
                sso_enabled=True,
                custom_plugins=True,
                analytics_enabled=True,
                backup_enabled=True
            )
        }
    
    async def list_tenants(self) -> List[Tenant]:
        """List all tenants"""
        try:
            # Get tenant namespaces from Kubernetes
            result = await self._run_kubectl([
                "get", "namespaces",
                "-l", "app.kubernetes.io/name=wordpress-tenant",
                "-o", "json"
            ])
            
            namespaces = json.loads(result.stdout)
            tenants = []
            
            for ns in namespaces.get("items", []):
                tenant_id = ns["metadata"]["name"]
                
                # Get tenant configuration
                tenant_config = await self._get_tenant_config(tenant_id)
                if tenant_config:
                    tenants.append(self._parse_tenant_from_config(tenant_config))
            
            return tenants
            
        except Exception as e:
            logger.error(f"Failed to list tenants: {e}")
            return []
    
    async def get_tenant(self, tenant_id: str) -> Optional[Tenant]:
        """Get tenant by ID"""
        try:
            tenant_config = await self._get_tenant_config(tenant_id)
            if tenant_config:
                return self._parse_tenant_from_config(tenant_config)
            return None
            
        except Exception as e:
            logger.error(f"Failed to get tenant {tenant_id}: {e}")
            return None
    
    async def create_tenant(
        self,
        tenant_id: str,
        display_name: str,
        admin_email: str,
        tier: TenantTier = TenantTier.FREE,
        custom_domains: List[str] = None,
        settings: TenantSettings = None
    ) -> Tenant:
        """Create a new tenant"""
        
        # Validate tenant ID
        if not self._validate_tenant_id(tenant_id):
            raise ValueError("Invalid tenant ID format")
        
        # Check if tenant already exists
        existing_tenant = await self.get_tenant(tenant_id)
        if existing_tenant:
            raise ValueError(f"Tenant {tenant_id} already exists")
        
        # Generate secure password
        admin_password = self._generate_password()
        
        # Create tenant object
        tenant = Tenant(
            id=tenant_id,
            display_name=display_name,
            admin_email=admin_email,
            admin_user=f"{tenant_id}-admin",
            admin_password=admin_password,
            tier=tier,
            status=TenantStatus.PENDING,
            features=self.tier_features[tier],
            resources=self.tier_configs[tier],
            settings=settings or TenantSettings(),
            custom_domains=custom_domains or [],
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        try:
            # Create Terraform configuration
            await self._create_terraform_config(tenant)
            
            # Apply Terraform
            await self._apply_terraform(tenant_id)
            
            # Update tenant status
            tenant.status = TenantStatus.ACTIVE
            tenant.updated_at = datetime.utcnow()
            
            # Save tenant configuration
            await self._save_tenant_config(tenant)
            
            logger.info(f"Successfully created tenant {tenant_id}")
            return tenant
            
        except Exception as e:
            logger.error(f"Failed to create tenant {tenant_id}: {e}")
            # Cleanup on failure
            await self._cleanup_failed_tenant(tenant_id)
            raise
    
    async def update_tenant(
        self,
        tenant_id: str,
        display_name: str = None,
        tier: TenantTier = None,
        custom_domains: List[str] = None,
        settings: TenantSettings = None
    ) -> Optional[Tenant]:
        """Update an existing tenant"""
        
        tenant = await self.get_tenant(tenant_id)
        if not tenant:
            return None
        
        # Update fields
        if display_name:
            tenant.display_name = display_name
        if tier and tier != tenant.tier:
            tenant.tier = tier
            tenant.resources = self.tier_configs[tier]
            tenant.features = self.tier_features[tier]
        if custom_domains is not None:
            tenant.custom_domains = custom_domains
        if settings:
            tenant.settings = settings
        
        tenant.updated_at = datetime.utcnow()
        
        try:
            # Update Terraform configuration
            await self._create_terraform_config(tenant)
            
            # Apply changes
            await self._apply_terraform(tenant_id)
            
            # Save updated configuration
            await self._save_tenant_config(tenant)
            
            logger.info(f"Successfully updated tenant {tenant_id}")
            return tenant
            
        except Exception as e:
            logger.error(f"Failed to update tenant {tenant_id}: {e}")
            raise
    
    async def delete_tenant(self, tenant_id: str) -> bool:
        """Delete a tenant"""
        
        tenant = await self.get_tenant(tenant_id)
        if not tenant:
            return False
        
        try:
            # Destroy Terraform resources
            await self._destroy_terraform(tenant_id)
            
            # Remove configuration files
            await self._remove_tenant_config(tenant_id)
            
            logger.info(f"Successfully deleted tenant {tenant_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to delete tenant {tenant_id}: {e}")
            return False
    
    async def get_tenant_usage(self, tenant_id: str, hours: int = 24) -> Optional[TenantUsageMetrics]:
        """Get tenant resource usage metrics"""
        
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=hours)
        
        try:
            # Get metrics from Kubernetes metrics API
            # This is a placeholder - in production, integrate with Prometheus/metrics server
            return TenantUsageMetrics(
                tenant_id=tenant_id,
                cpu_usage_hours=0.0,
                memory_usage_gb_hours=0.0,
                storage_usage_gb_hours=0.0,
                api_requests=0,
                content_workflows=0,
                database_queries=0,
                bandwidth_gb=0.0,
                period_start=start_time,
                period_end=end_time
            )
            
        except Exception as e:
            logger.error(f"Failed to get usage for tenant {tenant_id}: {e}")
            return None
    
    async def scale_tenant(self, tenant_id: str, new_tier: TenantTier) -> Optional[Tenant]:
        """Scale a tenant to a different tier"""
        
        tenant = await self.get_tenant(tenant_id)
        if not tenant:
            return None
        
        if tenant.tier == new_tier:
            return tenant
        
        return await self.update_tenant(tenant_id, tier=new_tier)
    
    async def test_tenant(self, tenant_id: str) -> Dict[str, Any]:
        """Test tenant functionality"""
        
        test_results = {
            "tenant_id": tenant_id,
            "tests": {},
            "overall_status": "unknown"
        }
        
        try:
            # Test namespace exists
            result = await self._run_kubectl(["get", "namespace", tenant_id])
            test_results["tests"]["namespace_exists"] = result.returncode == 0
            
            # Test pods are running
            result = await self._run_kubectl([
                "get", "pods", "-n", tenant_id,
                "-o", "jsonpath={.items[*].status.phase}"
            ])
            if result.returncode == 0:
                phases = result.stdout.strip().split()
                test_results["tests"]["pods_running"] = all(phase == "Running" for phase in phases)
            else:
                test_results["tests"]["pods_running"] = False
            
            # Test WordPress accessibility
            loadbalancer_ip = await self._get_loadbalancer_ip()
            if loadbalancer_ip:
                async with httpx.AsyncClient() as client:
                    try:
                        response = await client.get(
                            f"http://{loadbalancer_ip}/",
                            headers={"Host": f"wordpress-{tenant_id}.local"},
                            timeout=10
                        )
                        test_results["tests"]["wordpress_accessible"] = response.status_code == 200
                    except:
                        test_results["tests"]["wordpress_accessible"] = False
            else:
                test_results["tests"]["wordpress_accessible"] = False
            
            # Determine overall status
            all_tests_passed = all(test_results["tests"].values())
            test_results["overall_status"] = "healthy" if all_tests_passed else "unhealthy"
            
        except Exception as e:
            logger.error(f"Failed to test tenant {tenant_id}: {e}")
            test_results["overall_status"] = "error"
            test_results["error"] = str(e)
        
        return test_results
    
    # Private helper methods
    
    def _validate_tenant_id(self, tenant_id: str) -> bool:
        """Validate tenant ID format"""
        import re
        return bool(re.match(r'^[a-z0-9][a-z0-9-]*[a-z0-9]$', tenant_id)) and len(tenant_id) <= 20
    
    def _generate_password(self, length: int = 16) -> str:
        """Generate a secure password"""
        import secrets
        import string
        alphabet = string.ascii_letters + string.digits
        return ''.join(secrets.choice(alphabet) for _ in range(length))
    
    async def _get_tenant_config(self, tenant_id: str) -> Optional[Dict]:
        """Get tenant configuration from Kubernetes ConfigMap"""
        try:
            result = await self._run_kubectl([
                "get", "configmap", "tenant-config",
                "-n", tenant_id,
                "-o", "jsonpath={.data.tenant\\.json}"
            ])
            
            if result.returncode == 0:
                return json.loads(result.stdout)
            return None
            
        except Exception:
            return None
    
    def _parse_tenant_from_config(self, config: Dict) -> Tenant:
        """Parse tenant object from configuration"""
        return Tenant(
            id=config["tenant_id"],
            display_name=config["display_name"],
            admin_email=config.get("admin_email", ""),
            admin_user=f"{config['tenant_id']}-admin",
            admin_password="[REDACTED]",
            tier=TenantTier(config["tier"]),
            status=TenantStatus.ACTIVE,  # Assume active if config exists
            features=TenantFeatures(**config["features"]),
            resources=TenantResources(**config["resource_limits"]),
            settings=TenantSettings(**config["settings"]),
            custom_domains=config["custom_domains"],
            created_at=datetime.utcnow(),  # Placeholder
            updated_at=datetime.utcnow(),
            region=config["region"]
        )
    
    async def _create_terraform_config(self, tenant: Tenant) -> None:
        """Create Terraform configuration for tenant"""
        
        tfvars_path = self.terraform_dir / f"tenant-{tenant.id}.tfvars"
        
        config = {
            "wordpress_tenants": {
                tenant.id: {
                    "display_name": tenant.display_name,
                    "admin_user": tenant.admin_user,
                    "admin_password": tenant.admin_password,
                    "admin_email": tenant.admin_email,
                    "tier": tenant.tier.value,
                    "cpu_request": tenant.resources.cpu_request,
                    "cpu_limit": tenant.resources.cpu_limit,
                    "memory_request": tenant.resources.memory_request,
                    "memory_limit": tenant.resources.memory_limit,
                    "storage_size": tenant.resources.storage_size,
                    "db_cores": tenant.resources.db_cores,
                    "db_ram": tenant.resources.db_ram,
                    "db_storage": tenant.resources.db_storage,
                    "features": asdict(tenant.features),
                    "custom_domains": tenant.custom_domains,
                    "region": tenant.region,
                    "settings": asdict(tenant.settings)
                }
            }
        }
        
        # Write Terraform variables file
        with open(tfvars_path, 'w') as f:
            for key, value in config.items():
                f.write(f'{key} = {json.dumps(value, indent=2)}\n')
    
    async def _apply_terraform(self, tenant_id: str) -> None:
        """Apply Terraform configuration"""
        
        tfvars_file = f"tenant-{tenant_id}.tfvars"
        plan_file = f"tenant-{tenant_id}.plan"
        
        # Change to Terraform directory
        os.chdir(self.terraform_dir)
        
        try:
            # Plan
            result = subprocess.run([
                "terraform", "plan",
                f"-var-file={tfvars_file}",
                f"-out={plan_file}"
            ], capture_output=True, text=True, check=True)
            
            # Apply
            result = subprocess.run([
                "terraform", "apply", plan_file
            ], capture_output=True, text=True, check=True)
            
        finally:
            # Clean up plan file
            if os.path.exists(plan_file):
                os.remove(plan_file)
    
    async def _destroy_terraform(self, tenant_id: str) -> None:
        """Destroy Terraform resources for tenant"""
        
        tfvars_file = f"tenant-{tenant_id}.tfvars"
        
        # Change to Terraform directory
        os.chdir(self.terraform_dir)
        
        if os.path.exists(tfvars_file):
            result = subprocess.run([
                "terraform", "destroy",
                f"-var-file={tfvars_file}",
                "-auto-approve"
            ], capture_output=True, text=True, check=True)
    
    async def _save_tenant_config(self, tenant: Tenant) -> None:
        """Save tenant configuration to Kubernetes ConfigMap"""
        # This would update the ConfigMap with latest tenant info
        pass
    
    async def _remove_tenant_config(self, tenant_id: str) -> None:
        """Remove tenant configuration files"""
        tfvars_file = self.terraform_dir / f"tenant-{tenant_id}.tfvars"
        if tfvars_file.exists():
            tfvars_file.unlink()
    
    async def _cleanup_failed_tenant(self, tenant_id: str) -> None:
        """Cleanup resources for a failed tenant creation"""
        try:
            await self._destroy_terraform(tenant_id)
            await self._remove_tenant_config(tenant_id)
        except Exception as e:
            logger.error(f"Failed to cleanup tenant {tenant_id}: {e}")
    
    async def _run_kubectl(self, args: List[str]) -> subprocess.CompletedProcess:
        """Run kubectl command"""
        env = os.environ.copy()
        env["KUBECONFIG"] = str(self.kubeconfig_path)
        
        return subprocess.run(
            ["kubectl"] + args,
            capture_output=True,
            text=True,
            env=env
        )
    
    async def _get_loadbalancer_ip(self) -> Optional[str]:
        """Get LoadBalancer IP address"""
        try:
            result = await self._run_kubectl([
                "get", "service", "-n", "ingress-nginx",
                "ingress-nginx-controller",
                "-o", "jsonpath={.status.loadBalancer.ingress[0].ip}"
            ])
            
            if result.returncode == 0:
                return result.stdout.strip()
            return None
            
        except Exception:
            return None


# Example usage
async def main():
    """Example usage of TenantManager"""
    
    manager = TenantManager()
    
    # List tenants
    tenants = await manager.list_tenants()
    print(f"Found {len(tenants)} tenants")
    
    # Create a new tenant
    try:
        new_tenant = await manager.create_tenant(
            tenant_id="example-corp",
            display_name="Example Corporation",
            admin_email="admin@example.com",
            tier=TenantTier.PRO
        )
        print(f"Created tenant: {new_tenant.id}")
    except ValueError as e:
        print(f"Failed to create tenant: {e}")
    
    # Get tenant details
    tenant = await manager.get_tenant("example-corp")
    if tenant:
        print(f"Tenant details: {tenant.to_dict()}")
    
    # Test tenant
    test_results = await manager.test_tenant("example-corp")
    print(f"Test results: {test_results}")


if __name__ == "__main__":
    asyncio.run(main())