subtype {{.identifier}} is integer range {{?.x_min}}{{.x_min}}{{|.x_min}}integer'low{{/.x_min}} to {{?.x_max}}{{.x_max}}{{|.x_max}}integer'high{{/.x_max}};
type {{.identifier_v}} is array (integer range <>) of {{.qualified}};
