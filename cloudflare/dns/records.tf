# Static DNS records (apex, MX, SPF/DKIM/DMARC, verification, OVH mail).
# NOT included: cert-manager's ephemeral _acme-challenge TXTs (k8s-managed) and
# tunnel CNAMEs (live in cloudflare/tunnel/). Imported — see imports.tf.

resource "cloudflare_dns_record" "mx_bobr_pro_ec8f99" {
  zone_id  = cloudflare_zone.bobr_pro.id
  name     = "bobr.pro"
  type     = "MX"
  content  = "route3.mx.cloudflare.net"
  ttl      = 1
  proxied  = false
  priority = 86
}

resource "cloudflare_dns_record" "mx_bobr_pro_b53641" {
  zone_id  = cloudflare_zone.bobr_pro.id
  name     = "bobr.pro"
  type     = "MX"
  content  = "route2.mx.cloudflare.net"
  ttl      = 1
  proxied  = false
  priority = 63
}

resource "cloudflare_dns_record" "mx_bobr_pro_333e50" {
  zone_id  = cloudflare_zone.bobr_pro.id
  name     = "bobr.pro"
  type     = "MX"
  content  = "route1.mx.cloudflare.net"
  ttl      = 1
  proxied  = false
  priority = 5
}

resource "cloudflare_dns_record" "txt_bobr_pro_056b02" {
  zone_id = cloudflare_zone.bobr_pro.id
  name    = "bobr.pro"
  type    = "TXT"
  content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "txt_cf2024_1__domainkey_bobr_pro_e815da" {
  zone_id = cloudflare_zone.bobr_pro.id
  name    = "cf2024-1._domainkey.bobr.pro"
  type    = "TXT"
  content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "a_lan_miveal_eu_f9152a" {
  zone_id = cloudflare_zone.miveal_eu.id
  name    = "lan.miveal.eu"
  type    = "A"
  content = "79.110.199.171"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "a_mojadzialka_miveal_eu_a4ee47" {
  zone_id = cloudflare_zone.miveal_eu.id
  name    = "mojadzialka.miveal.eu"
  type    = "A"
  content = "79.110.199.171"
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "mx_send_miveal_eu_5b02f6" {
  zone_id  = cloudflare_zone.miveal_eu.id
  name     = "send.miveal.eu"
  type     = "MX"
  content  = "feedback-smtp.eu-west-1.amazonses.com"
  ttl      = 3600
  proxied  = false
  priority = 10
}

resource "cloudflare_dns_record" "txt_resend__domainkey_miveal_eu_19d4b0" {
  zone_id = cloudflare_zone.miveal_eu.id
  name    = "resend._domainkey.miveal.eu"
  type    = "TXT"
  content = "\"p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCypiGd7a92arwGFWSixH8cN1ujPJhp+h3/cpQSxw3YNkEoy+goSQUq8WB7Vvryh8KkV9cha4lNTtfPGxw5HrofQQGwgJLBcdn6TwiHqjfak/nzeANFkqIrZHrdLy7DaWe1HOx7H96pB4IKZVzibgSv52VXimIrdz6IShDTXkvz0QIDAQAB\""
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "txt_send_miveal_eu_4e25c6" {
  zone_id = cloudflare_zone.miveal_eu.id
  name    = "send.miveal.eu"
  type    = "TXT"
  content = "\"v=spf1 include:amazonses.com ~all\""
  ttl     = 3600
  proxied = false
}

resource "cloudflare_dns_record" "cname_ovhmo_selector_1__domainkey_mojerodos_pl_6c0fcf" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "ovhmo-selector-1._domainkey.mojerodos.pl"
  type    = "CNAME"
  content = "ovhmo-selector-1._domainkey.4574651.fh.dkim.mail.ovh.net"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "cname_ovhmo_selector_2__domainkey_mojerodos_pl_d7d21d" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "ovhmo-selector-2._domainkey.mojerodos.pl"
  type    = "CNAME"
  content = "ovhmo-selector-2._domainkey.4574652.fh.dkim.mail.ovh.net"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "cname_ovh_zimbra_ib3gunn1_mojerodos_pl_268f40" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "ovh-zimbra-ib3gunn1.mojerodos.pl"
  type    = "CNAME"
  content = "ovh.com"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "mx_mojerodos_pl_a00c19" {
  zone_id  = cloudflare_zone.mojerodos_pl.id
  name     = "mojerodos.pl"
  type     = "MX"
  content  = "mx4.mail.ovh.net"
  ttl      = 1
  proxied  = false
  priority = 200
}

resource "cloudflare_dns_record" "mx_mojerodos_pl_85891d" {
  zone_id  = cloudflare_zone.mojerodos_pl.id
  name     = "mojerodos.pl"
  type     = "MX"
  content  = "mx3.mail.ovh.net"
  ttl      = 1
  proxied  = false
  priority = 99
}

resource "cloudflare_dns_record" "mx_mojerodos_pl_d090b7" {
  zone_id  = cloudflare_zone.mojerodos_pl.id
  name     = "mojerodos.pl"
  type     = "MX"
  content  = "mx2.mail.ovh.net"
  ttl      = 1
  proxied  = false
  priority = 50
}

resource "cloudflare_dns_record" "mx_mojerodos_pl_3b2ecf" {
  zone_id  = cloudflare_zone.mojerodos_pl.id
  name     = "mojerodos.pl"
  type     = "MX"
  content  = "mx1.mail.ovh.net"
  ttl      = 1
  proxied  = false
  priority = 5
}

resource "cloudflare_dns_record" "mx_mojerodos_pl_0921b8" {
  zone_id  = cloudflare_zone.mojerodos_pl.id
  name     = "mojerodos.pl"
  type     = "MX"
  content  = "mx0.mail.ovh.net"
  ttl      = 1
  proxied  = false
  priority = 1
}

resource "cloudflare_dns_record" "mx_send_mojerodos_pl_03a328" {
  zone_id  = cloudflare_zone.mojerodos_pl.id
  name     = "send.mojerodos.pl"
  type     = "MX"
  content  = "feedback-smtp.eu-west-1.amazonses.com"
  ttl      = 1
  proxied  = false
  priority = 10
}

resource "cloudflare_dns_record" "txt__dmarc_mojerodos_pl_112035" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "_dmarc.mojerodos.pl"
  type    = "TXT"
  content = "\"v=DMARC1; p=none; rua=mailto:329770b332ea41cfb16d918738d28742@dmarc-reports.cloudflare.net;\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "txt_mojerodos_pl_6df832" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "mojerodos.pl"
  type    = "TXT"
  content = "\"v=spf1 include:mx.ovh.com include:amazonses.com ~all\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "txt_mojerodos_pl_a69a46" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "mojerodos.pl"
  type    = "TXT"
  content = "\"1|www.mojerodos.pl\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "txt_resend__domainkey_mojerodos_pl_797f32" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "resend._domainkey.mojerodos.pl"
  type    = "TXT"
  content = "\"p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCXjJUFdYNnPSaGdBYbYfScfnKNVds1iZ5uhvZ1W8JWYqytzgJDjbi3G2p8BngZULwltHS08m1gHH+ywWlmzRN/I0YK1KEfdWAdBwsLzL2gA2EncP1FtBffAOjCEFxK/z/QFsUlDdJhUgPmAe7gLG+uzW4CUVC3dWWrxAsOYPgYzwIDAQAB\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "txt_send_mojerodos_pl_5ef756" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "send.mojerodos.pl"
  type    = "TXT"
  content = "\"v=spf1 include:amazonses.com ~all\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "txt_www_mojerodos_pl_e5fc35" {
  zone_id = cloudflare_zone.mojerodos_pl.id
  name    = "www.mojerodos.pl"
  type    = "TXT"
  content = "\"3|welcome\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "a_wroher_eu_0e6ec3" {
  zone_id = cloudflare_zone.wroher_eu.id
  name    = "wroher.eu"
  type    = "A"
  content = "79.110.199.171"
  ttl     = 1
  proxied = true
}
