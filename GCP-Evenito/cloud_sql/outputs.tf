output "db_host" {
  value = "${google_sql_database_instance.platform-api.connection_name}"
}
