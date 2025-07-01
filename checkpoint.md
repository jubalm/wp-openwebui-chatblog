check last githug workflow run using gh. let's investigate the last deploy  
X helm-charts Unified Terraform Deployment · 15989560085               │
 │    Triggered via workflow_dispatch about 22 minutes ago                   │
 │                                                                           │
 │    JOBS                                                                   │
 │    ✓ 1. Plan Infrastructure in 14s (ID 45100170326)                       │
 │    ✓ 1. Apply Infrastructure in 18s (ID 45100179527)                      │
 │    X 2. Plan Platform in 19s (ID 45100289206)                             │
 │      ✓ Set up job                                                         │
 │      ✓ Checkout                                                           │
 │      ✓ Download Kubeconfig                                                │
 │      ✓ Setup Terraform                                                    │
 │      ✓ Terraform Init                                                     │
 │      X Terraform Plan                                                     │
 │      - Upload Plan                                                        │
 │      ✓ Post Checkout                                                      │
 │      ✓ Complete job                                                       │
 │    - 2. Apply Platform & Inject Secrets (ID 45100303281)                  │
 │    - 3. Plan Tenants (ID 45100303326)                                     │
 │    - 3. Apply Tenants in 0s (ID 45100303352)                              │
 │                                                                           │
 │    ANNOTATIONS                                                            │
 │    X Process completed with exit code 1.                                  │
 │    2. Plan Platform: .github#20                                           │
 │                                                                           │
 │    X Terraform exited with code 1.                                        │
 │    2. Plan Platform: .github#19                                           │
 │                                                                           │
 │                                                                           │
 │    ARTIFACTS                                                              │
 │    infra-plan                                                             │
 │    kubeconfig                                                             │
 │                                                                           │
 │    To see what failed, try: gh run view 15989560085                       │
 │    --log-failed                                                           │
 │    View this run on GitHub:                                               │
 │    https://github.com/jubalm/wp-openwebui-chatblog/actions/run            │
 │    s/15989560085   

 