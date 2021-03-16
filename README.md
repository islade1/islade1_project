# < islade1-project > #

## Terraform ##

1. С помощью Terraform получаем доступ к AWS; 
``` 
provider "aws" {
  profile = "iSlade1"
  region  = "eu-central-1"
}
```
2. Далее получаем последний AMI Ubuntu;
```
data "aws_ami" "Latest_Ubuntu" {
  owners      = ["099720109477"] # AMI Owner
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] # Latest Ubuntu 20.04 LTS AMI
  }
}
```
3. Создаем Security Group;
```
resource "aws_security_group" "allow_ports" {
  name        = "WebServer Security Group"
  description = "Allow TCP inbound traffic"

  ingress {
    description = "HTTPS allow"
    from_port   = 443 # Allow HTTPS conection
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP allow"
    from_port   = 80 # Allow HTTP conection
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP allow"
    from_port   = 22 # Allow TCP conection
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS allow"
    from_port   = 8080 # Allow Jenkins conection
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
4. Разворачиваем 3 инстанса, используем полученный образ, добовляем Security Group id и запускаем .bash скрипт;
```
resource "aws_instance" "Jenkins" {
  ami                    = data.aws_ami.Latest_Ubuntu.id # Ubuntu 20.04 LTS AMI
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ports.id] # Attach Security Group
  user_data              = file("jenkins.bash")                # Execute script on AWS instance
  tags = {
    Name = "Jenkins" # Name tag for Ubuntu Environment in AWS
  }
}

# Creating AWS instances on Ubuntu for Apache WebServer

resource "aws_instance" "Test_Env" {
  ami                    = data.aws_ami.Latest_Ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ports.id]
  user_data              = file("apache.bash")
  tags = {
    Name = "Test_Env"
  }
}

resource "aws_instance" "Prod_Env" {
  ami                    = data.aws_ami.Latest_Ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ports.id]
  user_data              = file("apache.bash")
  tags = {
    Name = "Prod_Env"
  }
}
```

## Jenkins ##

### Создаем 3 Jenkins jobs ###

1. GitHub pull request - эта задача триггерит удалённый репозиторий на GitHub с помощью Webhook, для настройки вебхука потребуется добавить api token в системные настойки Jenkins, с помощью плагина promoted builds, создаётся два критеррия: 1-й разрешает без approve, deploy на Test_Env, второй же запрещает deploy на Prod_Env без approve. С помощью плагина GitHub pull request builder, мы настраиваем права merge новой ветки в master, используем вебхук для отслеживания изменений в репозитории. Pull request осуществляется таким образом, что после того как разработчик запушил свои измения в новой ветке на репозиторий и создал pull request из ветки например fitch в ветку master, Jenkins запускает build изменений на Test_Env, но при этом невозможно сделать merge изменений в ветку master, пока reviewer не даст свой approve на внесение изменений в основую ветку, после того как изменения были одобрены, разработчик пишет коментарий (тот который задан в настройках trigger build) под pull request, в моём случае это "start build", Jenkins снова запускает build проверяет все ли разрешения даны и после автоматически делает merge в ветку master, после этого удаляет ветку fitch автоматически;
2. Deploy to Test - эта задача запускается автоматически, когда Jenkins запускает Build при создании pull request. Страничка index.html разворачивается на тестовом сервере;
3. Deploy to Prod - эта задача после успешного завершения 1-й и 2-й задач, запускается атвоматически когда мы даём approve ранее настроенный в плагине promoted builds. Страничка index.html разворачивается на продакшн сервере.  

