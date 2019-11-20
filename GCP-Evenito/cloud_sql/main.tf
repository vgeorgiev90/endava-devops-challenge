resource "google_sql_database_instance" "platform-api" {
  name = "${var.database_instance_name}"
  region = "${var.database_region}"
  database_version = "${var.database_version}"
  settings {
     tier = "${var.database_tier}"
     authorized_gae_applications = [] 
     disk_size = "${var.database_disk_size}"
     backup_configuration {
       enabled = "true"
     }
  }
  project = "${var.database_project}"
}

/*
resource "google_sql_database" "pgdb" {
  name = "${var.database_name}"
  instance = "${google_sql_database_instance.platform-api.name}"
}
*/
resource "google_sql_user" "postgres" {
  name = "${var.database_user}"
  instance = "${google_sql_database_instance.platform-api.name}"
  password = "${var.database_pass}"
}
