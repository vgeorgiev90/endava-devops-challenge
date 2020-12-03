variable "region" {
	type = string
	default = "eu-west-1"
}

variable "retain_count" {
	type = number
	default = 7
}

variable "target_tags" {
	type = map
	default = {
          Snapshots = "true"
          DlmBackups = "true"
        }
}
