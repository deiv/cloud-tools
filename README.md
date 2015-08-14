## About
This is a collection of tools that provides a frontend to *cloud-scripts*: a set of scripts to perform Archive rebuild on the cloud.

It mostly contains a mix of a yaml configuration and a DSL that provides an easy way to express and maintain the Debian archive rebuilds.

## Configuration files

### config.yml (global config file)

This file is divided into the next sections:

- #### :instances:
  Defines a list of instances, and their properties, each of one could be later referenced in the recipes. For example:
  ```Ruby
  - !ruby/struct:Instance
    name: medium
    type: m1.medium
    price: .16
  ```
  ###### Instance properties
    - **name**: the name used to reference this instance in recipes
    - **type**: the ec2 type of instance
    - **price**: spot instance price


- #### :regions:
  Defines the supported ec2 regions and their dependent properties. For example:
  ```Ruby
    - &sa-east !ruby/struct:Region
      name: us-west-2
      ami: ami-1235a576
  ```
  ###### Region properties
    - **name**: the ec2 name of the region
    - **ami**: ami used by instances in each region.


- #### :credentials:
  A list of credentials, each one having the Amazon Api keys. Later you can specify the one used in **defaults** section.
  ```Ruby
    - &qa !ruby/struct:Credentials
      name: qa
      id: AKIAHJ934HUIHOPWKOPK
      secret: o/UHudeihipHDUe897347389UDIiH
  ```
  ###### Credentials properties
    - **name**: reference id (*not used atm, later we will allow to override this by commandline*).
    - **id**: Amazon API Key ID
    - **secret**: Amazon API Key Secret


- #### :masternode:
  Configuration related to masternode machine.
  ```Ruby
    :host: aws-logs.debian.net
    :ssh-user: deiv
    :work-dir: /home/deiv/cloud-scripts
    :ruby-interpreter: ruby
  ```
  ###### Properties
    - **host**: hostname/ip
    - **ssh-user**: masternode user
    - **work-dir**: cloud-scripts directory
    - **ruby-interpreter**: ruby binary to use


- #### :defaults:
  Default properties to be used (*if not overriden by recipes or commandline*).
  ```Ruby
    :region: *sa-east
    :credentials: *qa
    :tags:
      Team: Debian-QA
    :securitygroups:
      - Debian-QA
      - no-network-access
    :vpc-subnet-id: subnet-f0b10995
    :vpc-securitygroups-ids:
      - sg-97b7f8f2
  ```
  ###### Properties
    - **region**: default region to be used
    - **credentials**: default credentials
    - **tags**: a hash with the tags added to each started Amazon resource (*this are mixed, not overriden, with each recipe resource tag level property; see instance TAG property*)
    - **securitygroups**: name of the  security groups added to each started amazon resource  (if the instance did not belongs to a VPC, see security group property for more info)
    - **vpc-subnet-id**: id of the VPC in with each instance will be started
    - **vpc-securitygroups-ids**: ids of the security groups for each instance (if started in a VPC)


### Recipes

Recipes are simply DSL's that has the next characteristics:

- A *recipe* is a file that contains an *instruction* to build up some *product*.
- A *recipe* could contains multiple *instructions*.
- An *instruction* could generate more than one *product*.

#### Build Set instruction
It haves, at least, one *nodes* definition and one *tasks* definition. It always generates, at least, one *BuildSet* (on where the *tasks* will be, on some way, executed on the *nodes*).

A simply recipe with one *build_set* intruction would be:

```Ruby
build_set "simply" do
  nodes do
    instance "mlarge"
    count 30
    slots 3
  end

  task "normal" do
    no_arch_all

    mode "binary-only"
    mode "gcc-unstable"

    log_id "gcc5"
  end
end
```

This recipe generates one product: a *BuildSet*.

The *nodes part*, simply defines a group of 30 nodes (count = 30) where the instance type will be *mlarge* and each instance will spawn 3 parallel jobs (slots in masternode way).

The *task* part defines some arguments needed to customize the generation of tasks.


### Properties list

Much of this properties could be specified in both, the global configuration file (*config level*) or in the cookbook recipes (*recipe level*).

If multiple levels are given, only one of this pair of rules are applied, dependently of the type of property:
- The values of all the properties are mixed.
- Only the value that takes preference is used. The order of preference is (from lower to upper): *config level -> recipe level -> commandline level*

#### Instance TAG [recipe, config#defaults]:

**multiple level rule**: by mixing

Property levels:
- recipe
```ruby
  nodes do
    instance "xlarge-hvm"
    tag "Team", "Debian-QA"
  end
```

- config#defaults
```ruby
  :defaults:
    :tags:
      Team: Debian-QA
```

#### Instance Security groups [recipe, config#defaults]:

**multiple level rule**: by mixing

Property levels:
- recipe
```ruby
  nodes do
    instance "xlarge-hvm"
    securitygroups:
      - instance-sg1
      - instance-sg2
  end
```

- config#defaults
```ruby
  :defaults:
    :securitygroups:
      - default
      - no-network-access
```


#### Instance VPC [recipe, config#defaults]:

**multiple level rule**: by preference

- recipe
```ruby
nodes do
    instance "xlarge-hvm"
    vpc_subnet_id "subnet-id123"
end
```

- config#defaults
```ruby
  :defaults:
    :vpc-subnet-id: subnet-12674563
```

#### Instance VPC security groups [recipe, config#defaults]:

Here must be used the id of the security group not the name (*instead of the name like in the instance security group tag*)

**multiple level rule**: by mixing

- recipe
```ruby
nodes do
    instance "xlarge-hvm"
    vpc_securitygroup_id "sg-1234567890"
    vpc_securitygroup_id "sg-0987654321"
end
```

- config#defaults
```ruby
  :defaults:
    :vpc-securitygroups-ids:
        - sg-1234567890
        - sg-0987654321
```

## TODO:

  - Tests on new account
  - Change ami property of regions section in config to be a hash that specifies a key/value pair with an ami-name/ami-id- Later the ami-name could be referenced in a new instance property.
