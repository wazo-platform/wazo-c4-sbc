id(int) domain(string) did(string) last_modified(int)
{{range $index, $service := service "sbc"}}{{ add $index 1 }}:{{.Address}}:{{.Address}}:0
{{end}}
