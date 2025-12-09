# 1. VPC Network (like AWS VPC / OCI VCN)
resource "google_compute_network" "news_vpc" {
  name                    = "news-vpc"
  auto_create_subnetworks = false
}

# 2. Private subnet (for Cloud SQL, etc.)
resource "google_compute_subnetwork" "news_private_subnet" {
  name          = "news-private-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.news_vpc.id
  private_ip_google_access = true
}

# (Optional) Public subnet if you ever need GCE/other resources
resource "google_compute_subnetwork" "news_public_subnet" {
  name          = "news-public-subnet"
  ip_cidr_range = "10.10.1.0/24"
  region        = var.region
  network       = google_compute_network.news_vpc.id
  private_ip_google_access = true
}

# 3. Serverless VPC Access Connector
# Cloud Functions / Cloud Run use this to reach private resources (e.g. Cloud SQL via private IP)
resource "google_vpc_access_connector" "serverless_connector" {
  name   = "news-serverless-connector"
  region = var.region
  network = google_compute_network.news_vpc.name

  ip_cidr_range = "10.10.2.0/28" # small /28 just for connector
}

output "news_vpc_id" {
  value = google_compute_network.news_vpc.id
}

output "serverless_connector_name" {
  value = google_vpc_access_connector.serverless_connector.name
}
