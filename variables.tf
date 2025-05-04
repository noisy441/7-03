variable "flow" {
  type    = string
  default = "24-01"
}

variable "cloud_id" {
  type    = string
  default = "b1gt4ptl2kqr88n6tel7"
}
variable "folder_id" {
  type    = string
  default = "b1gnhl2isavkofciik7f"
}

variable "test" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
}

