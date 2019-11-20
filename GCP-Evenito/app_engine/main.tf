## Standart App Engine instance

resource "google_app_engine_application" "app_engine" {
   project  =  "${var.app_engine_project}"
   location_id = "${var.app_engine_location}"
}

resource "null_resource" "wait" {
provisioner "local-exec" {
  command = "echo 'Waiting for app engine to become active' && sleep 180"
}
}

resource "null_resource" "appdeploy" {
provisioner "local-exec" {
   command = "/root/evenito-deploy/application.py --cmd deploy-app-engine --sa ${var.credentials} --database ${var.app_engine_db_host} --project ${var.app_engine_project}"
}
}


