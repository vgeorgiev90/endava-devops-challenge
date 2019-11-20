provider "google" {
  project = "${var.project_id}"
  credentials = "${file("${var.credentials_file}")}"
  region = "${var.app_engine_location}"
}


module "app_engine" {
  source = "./app_engine"
  app_engine_project = "${var.project_id}"
  credentials = "${var.credentials_file}"
  app_engine_location = "${var.app_engine_location}"
  app_engine_db_host = "${module.cloud_sql.db_host}"
}

module "cloud_sql" {
  source = "./cloud_sql"
  database_version = "${var.database_version}"
  database_instance_name = "${var.database_instance_name}"
  database_region = "${var.app_engine_location}"
  database_project = "${var.project_id}"
  database_name = "${var.database_name}"
  database_tier = "${var.database_tier}"
  database_disk_size = "${var.database_disk_size}"
  database_user = "${var.database_user}"
  database_pass = "${var.database_pass}"
}
