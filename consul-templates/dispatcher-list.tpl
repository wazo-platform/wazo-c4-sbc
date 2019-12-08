# setid(int) destination(sip uri) flags(int,opt) priority(int,opt) attributes(str,opt)
{{range $index, $service := service "router"}}1 sip:{{.Address}}:{{.Port}} 16 5
{{end}}
