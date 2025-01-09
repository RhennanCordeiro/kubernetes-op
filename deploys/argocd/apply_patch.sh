kubectl patch deployment argocd-server -n argocd --patch "$(cat patch_http_argo.yml)"
