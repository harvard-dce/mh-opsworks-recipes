# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-engage-nginx-proxy

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package('nginx')

storage_info = node.fetch(
  :storage, {
    export_root: '/var/tmp',
    network: '10.0.0.0/8',
    layer_shortname: 'storage'
  }
)

ssl_info = node.fetch(
  :ssl, {
    # Dummy self-signed cert.
    certificate: "-----BEGIN CERTIFICATE-----\nMIIDvzCCAqegAwIBAgIJANg1Xye10w+RMA0GCSqGSIb3DQEBCwUAMHYxCzAJBgNV\nBAYTAlVTMQswCQYDVQQIDAJNQTESMBAGA1UEBwwJQ2FtYnJpZGdlMSAwHgYDVQQK\nDBdIYXJ2YXJkIERDRSBTZWxmLXNpZ25lZDEkMCIGA1UEAwwbc2VsZi1zaWduZWQu\nZGNlLmhhcnZhcmQuZWR1MB4XDTE1MDcxMzIwMzQyOFoXDTI1MDcxMDIwMzQyOFow\ndjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAk1BMRIwEAYDVQQHDAlDYW1icmlkZ2Ux\nIDAeBgNVBAoMF0hhcnZhcmQgRENFIFNlbGYtc2lnbmVkMSQwIgYDVQQDDBtzZWxm\nLXNpZ25lZC5kY2UuaGFydmFyZC5lZHUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\nggEKAoIBAQCt36/OLrRa3vui1ns7ey67btL/AN6lw2scwO0iurKUw5vomfEqjhks\n04dsBKTheSjYH4UroKN9ubJeVIZ+FL3ewSVLVMLG10TSya1vm2J0xR3nrWnbL9uo\nz7lERmQSXzllr5PHj+q3aI3ewTXQk8Ic71NFGBGDcDBRPdWEzyqsfvFvMVACGUBH\nrDyWO4WBbLp3gzbwITnQhGXz+f9cha1IiBYrrbysDDuw81Fa2HEiDiA3ghGVR4q9\nDwVjpf1YpZyaMxRs28pUZ8Eu5gyfemznQIW1pRnyN2/77IZsFooMzQ+q0jxjjTzb\nuNoQSL+Gfpo5Rxvg+bR5+qyz4v07eFeRAgMBAAGjUDBOMB0GA1UdDgQWBBQQKYCF\n2ey1VaoiL0p10diP4nH7mjAfBgNVHSMEGDAWgBQQKYCF2ey1VaoiL0p10diP4nH7\nmjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAyHRUGjkwKbnJDKAT8\n9Lce8qNxEtuwz+87/YgM2rrXNkSN9WfrZNFsM2T5sCtC5hxzI/cK34e8Mlcejx3+\nBG7ioH+3qyanIVvqMWJ1UGliWZ3W3Ol20ZgPYrkQrWMZBQfTJGNZsu3qCrloy91s\nwXxIPtjMPiDvmW8s96oDX9eceFofcFIvMBW60Y68nBQakzN0bdPobB0zpIg3VrKe\nMBPsYtmTtTGEf4MgKzjYWq0detrmZqF4pq4l8qzU66VTSmgjjEDgg0kq/abx+/Ut\nK8bq+Wo7AjgVVZf/IaUUr8B6/uOdnQQRDyBjqCH+lH3g/ZpZ2OJBvtWGj7DtZHWI\ny5IO\n-----END CERTIFICATE-----\n",
    # Dummy self-signed key.
    key: "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCt36/OLrRa3vui\n1ns7ey67btL/AN6lw2scwO0iurKUw5vomfEqjhks04dsBKTheSjYH4UroKN9ubJe\nVIZ+FL3ewSVLVMLG10TSya1vm2J0xR3nrWnbL9uoz7lERmQSXzllr5PHj+q3aI3e\nwTXQk8Ic71NFGBGDcDBRPdWEzyqsfvFvMVACGUBHrDyWO4WBbLp3gzbwITnQhGXz\n+f9cha1IiBYrrbysDDuw81Fa2HEiDiA3ghGVR4q9DwVjpf1YpZyaMxRs28pUZ8Eu\n5gyfemznQIW1pRnyN2/77IZsFooMzQ+q0jxjjTzbuNoQSL+Gfpo5Rxvg+bR5+qyz\n4v07eFeRAgMBAAECggEAWEyauXiaevN2kzGdD431I5aabIoCh+gAA3AufU6W1lmo\nWa2j/dqACnW59i89lIu1JFyNgqRnorelT6ZZTro12mP4DpOS/uvftbRZ8a3ViDt6\nfmdgtMFPKiGjknq042ecfHl38QazSkU8lv1D2RLQp2UawqIAcuGMiBWA05tproNK\nvSyKs3MueGeOvWTQh2bvQVHH0OOC594QexxquDme9DJDgEgQq1UKJW8Hzu3oQbQJ\n9/UFjcPXmkO/+2DN0nLW+O8w1HtvVfr6Pa0UusR5WgFgNlvMBAc3XG+2V5iG/5By\ngTV0zkoBf4F5UqBOn9x/+kY/hrS6CPm+fgYn1ErwAQKBgQDX2u0rXDtsqOZJSB5K\neZBaUGHLZjzXNenCRcMKm+m/DGR8UjAKhEPdBGrQgP2g4LqpHbhWBLrdWaauUM/d\nX5XHeY6sed+VhSIg30HrNUa8dG93rDTnErBaUQb4tLs3iKmFOxpsZEbFO0Pw2mRH\nNH3kXSgr/rvOdG6PUwarfr7fgQKBgQDONfwt4NFV8EqMjNZANp2yh9MP7HH6bisi\nvaM6T/90Om//q4ciWnGEe8IDbZYln01/tzOjRIsY/xSDM2Hccbn3GLAFxeDPMIKH\nTr0cSxJKU++a7Dl9zvcg9jzdjCsDUfoUyNn209syzcziSX5/TaAKXzQbRhhrC/bK\nE9RaBouAEQKBgQCK4tpnY9j4eVRzImwbD0zKT54c+ZN8Bbx6u9hbIyarPpYJR/iR\nS7k+pHD154lJ0k9IMU9CSZjSg7SzxFt63N3Kk3Qxldk+o4LqE7yeUpFJAMIYBj2j\n0GqYMjqCHAe6G7y3dOfzhjHjBdcZSevrxOKb5TTL2gONO21H2uwXvF2kAQKBgF7q\nrncXooOiJU5ojT3lZdUFe/s6ZIRXLXfCPl3a8MS5GVBfzcXcR6AprvYQ/Sm4F94P\nn68pH7WTxAdYIVVs66J3NJ6TpJT5yTsq3RUm4PZhiEqRLS1hlJMRhJadrDbNBwWG\nJf3dKmpKHGKUXauPOXlMtRlQvHCZgzEky3vcw11hAoGBAJoXXOOXpMAHcpgWVttT\nYauJB3ekj8lVMX2l4lEyQ0o/1ODemJ1u+571TCqnRtQF9RwtwkR7m3+ivmgF/njV\n6dCrgelCpFYGHDVuw/Ieiqz7Fx8J++9SvXi9NM9a7fI2Td6/V3d1dYi/VHifYr5F\nQmBPCO5TwRB13PcVR2u7PuW1\n-----END PRIVATE KEY-----\n",
    chain: ''
  }
)

directory '/etc/nginx/ssl' do
  owner 'root'
  group 'root'
  mode '0700'
end

cert_content = ''

# Store the certificate and key
if ! ssl_info[:certificate].empty? && ! ssl_info[:key].empty?
  # Concatenate the cert and the chain cert
  cert_content = %Q|#{ssl_info[:certificate]}#{ssl_info[:chain]}|
  file "/etc/nginx/ssl/certificate.cert" do
    owner 'root'
    group 'root'
    content cert_content
    mode '0600'
  end

  file "/etc/nginx/ssl/certificate.key" do
    owner 'root'
    group 'root'
    content ssl_info[:key]
    mode '0600'
  end
end

certificate_exists = ! cert_content.empty?

template %Q|/etc/nginx/sites-enabled/default| do
  source 'engage-nginx-proxy-conf.erb'
  variables({
    export_root: storage_info[:export_root],
    matterhorn_backend_http_port: 8080,
    certificate_exists: certificate_exists
  })
end

execute 'service nginx reload'
