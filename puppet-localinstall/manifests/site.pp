Exec { path => '/sbin:/bin:/usr/sbin:/usr/bin', }

#Package { 
#    allow_virtual => true,
#}

node 'master1.example.com' {
  include openshift3::master
}

node 'master2.example.com' {
  include openshift3::master
}

