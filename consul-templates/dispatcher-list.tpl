# setid(int) destination(sip uri) flags(int,opt) priority(int,opt) attributes(str,opt)
{{range $index, $service := service "router"}}1 sip:{{.Address}}:{{.Port}} 16 {{ if .Tags | contains "primary" }}10{{else}}5{{end}}
{{end}}
