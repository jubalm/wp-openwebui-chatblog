# OpenAI API Configuration Guide

> **Configuration Template**: IONOS OpenAI compatible endpoint configuration (replaces Ollama)

## Overview

This platform uses the IONOS OpenAI compatible endpoint instead of Ollama for AI content generation. The endpoint provides OpenAI-compatible API access through IONOS infrastructure.

## Configuration

### API Endpoint
- **Base URL**: `https://openai.inference.de-txl.ionos.com/v1`
- **Compatibility**: OpenAI API v1 compatible
- **Authentication**: API Key required

### Setting Up API Key

1. **Obtain API Key**: Get your IONOS OpenAI API key from your IONOS account
2. **Update Configuration**: Edit `charts/openwebui/values.yaml`
3. **Replace Placeholder**: Change `openai_api_key: "REPLACE_ME"` to your actual API key

```yaml
secret:
  create: true
  name: openwebui-env-secrets
  openai_api_key: "your-actual-api-key-here"
  openai_api_base_url: "https://openai.inference.de-txl.ionos.com/v1"
```

### Environment Variables

The following environment variables are automatically configured:
- `OPENAI_API_KEY`: Your IONOS OpenAI API key
- `OPENAI_API_BASE_URL`: IONOS OpenAI endpoint URL

## Migration from Ollama

### Configuration Changes
- Ollama integration disabled (`ollama.enabled: false`)
- OpenAI API configuration enabled
- Environment variables configured for IONOS endpoint
- Documentation templates updated for new setup

### Benefits of IONOS OpenAI API
- **Hosted Service**: No need to manage local Ollama installation
- **Scalability**: Automatic scaling through IONOS infrastructure
- **Reliability**: Enterprise-grade availability and performance
- **API Compatibility**: Standard OpenAI API interface

## Testing Configuration

After updating the API key, test the configuration:

```bash
# Test OpenWebUI connectivity
curl -H "Host: openwebui.local" http://<loadbalancer-ip>/api/config

# Check API configuration
kubectl get secrets openwebui-env-secrets -o yaml
```

## Troubleshooting

### Common Issues
1. **Invalid API Key**: Ensure the API key is correctly set in values.yaml
2. **Network Connectivity**: Verify cluster can reach IONOS OpenAI endpoint
3. **Environment Variables**: Check that secrets are properly mounted

### Verification Steps
1. Check pod logs: `kubectl logs -l app=openwebui`
2. Verify secrets: `kubectl describe secret openwebui-env-secrets`
3. Test API endpoint: `curl -H "Authorization: Bearer YOUR_API_KEY" https://openai.inference.de-txl.ionos.com/v1/models`

## Support

For issues related to:
- **API Key**: Contact IONOS support
- **Platform Configuration**: See main project documentation
- **Integration Issues**: Check the troubleshooting section in the main README