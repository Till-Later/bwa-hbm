{{?.is_input}}
{{.x_wrapname}}_clk   <= {{.identifier}}.clk;
{{.x_wrapname}}_rst_n <= {{.identifier}}.rst_n;
{{|.is_input}}
{{.identifier}}.clk   <= {{.x_wrapname}}_clk;
{{.identifier}}.rst_n <= {{.x_wrapname}}_rst_n;
{{/.is_input}}
