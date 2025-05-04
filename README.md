# Домашнее задание к занятию "`Подъём инфраструктуры в Yandex Cloud`" - `Дудин Сергей Васильевич`


### Инструкция по выполнению домашнего задания

   1. Сделайте `fork` данного репозитория к себе в Github и переименуйте его по названию или номеру занятия, например, https://github.com/имя-вашего-репозитория/git-hw или  https://github.com/имя-вашего-репозитория/7-1-ansible-hw).
   2. Выполните клонирование данного репозитория к себе на ПК с помощью команды `git clone`.
   3. Выполните домашнее задание и заполните у себя локально этот файл README.md:
      - впишите вверху название занятия и вашу фамилию и имя
      - в каждом задании добавьте решение в требуемом виде (текст/код/скриншоты/ссылка)
      - для корректного добавления скриншотов воспользуйтесь [инструкцией "Как вставить скриншот в шаблон с решением](https://github.com/netology-code/sys-pattern-homework/blob/main/screen-instruction.md)
      - при оформлении используйте возможности языка разметки md (коротко об этом можно посмотреть в [инструкции  по MarkDown](https://github.com/netology-code/sys-pattern-homework/blob/main/md-instruction.md))
   4. После завершения работы над домашним заданием сделайте коммит (`git commit -m "comment"`) и отправьте его на Github (`git push origin`);
   5. Для проверки домашнего задания преподавателем в личном кабинете прикрепите и отправьте ссылку на решение в виде md-файла в вашем Github.
   6. Любые вопросы по выполнению заданий спрашивайте в чате учебной группы и/или в разделе “Вопросы по заданию” в личном кабинете.
   
Желаем успехов в выполнении домашнего задания!
   
### Дополнительные материалы, которые могут быть полезны для выполнения задания

1. [Руководство по оформлению Markdown файлов](https://gist.github.com/Jekins/2bf2d0638163f1294637#Code)
____________________________________________________

1. Создать сервисный аккаунт в облаке. Выдать права editor
2. Выпустить авторизованный ключ для этого аккаунта и скачать его по пути ~/.authorized_key.json . 
3. Вписать в переменные cloud_id и folder_id в variables.tf
4. Изменить ssh-ключ в файле cloud-init.yml (ssh-keygen -t ed25519). cp terraformrc ~/.terraformrc
5. terraform init && terraform apply
6. rm ~/.ssh/known_hosts. Выполнить playbook ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ./hosts.ini test.yml
7. По окончании выполнить terraform destroy

https://www.jeffgeerling.com/blog/2022/using-ansible-playbook-ssh-bastion-jump-host

Настройка доступа по ssh через ssh config: 
~/.ssh/config
```
Host 89.169.142.236  #адрес вашего бастиона
   User user

Host 10.0.*
        ProxyJump 89.169.142.236
        User user

Host *.ru-central1.internal
        ProxyJump 89.169.142.236
        User user

```

Или более простой для понимания, но менее удобный для частого применения: ssh -J <jump server> <remote server>

---

### Задание 1 и 2 

1. `Повторить демонстрацию лекции(развернуть vpc, 2 веб сервера, бастион сервер)`
2. `С помощью ansible подключиться к web-a и web-b , установить на них nginx.(написать нужный ansible playbook) Провести тестирование и приложить скриншоты развернутых в облаке ВМ, успешно отработавшего ansible playbook.`

### Решение 1 и 2

**install_nginx.yml**

```
---
- hosts: webservers
  become: true
  tasks:
    - name: install nginx
      apt:
        name: nginx
        state: latest

    - name: copy nginx configuration
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'

    - name: create web root directory
      file:
        path: /var/www/html
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    - name: start nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: check nginx status
      command: systemctl status nginx
      register: nginx_status
      changed_when: false

    - name: display nginx status
      debug:
        var: nginx_status.stdout_lines

```

**nginx.conf.j2**

```
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] '
    '"$request" $status $body_bytes_sent '
    '"$http_referer" "$http_user_agent"';

    access_log /var/log/nginx/access.log main;

    sendfile        on;
    keepalive_timeout 65;

    server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;
        index index.html index.htm;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
        }
    }
}


```
`Скриншоты`

![Скриншот 1](https://github.com/noisy441/7-03/blob/main/img/img1.png)`

![Скриншот 2](https://github.com/noisy441/7-03/blob/main/img/img2.png)`

![Скриншот 3](https://github.com/noisy441/7-03/blob/main/img/img3.png)`

![Скриншот 4](https://github.com/noisy441/7-03/blob/main/img/img4.png)`

---

### Задание 3


1. `Добавить еще одну виртуальную машину`
2. `Установить на нее любую базу данных`
3. `Выполнить проверку состояния запущенных служб через Ansible`

### Решение 3

`Я создал еще одну виртуальную машину с именем web-c. Для более удобного использования ansible, адрес новой машины записывается в hosts.ini в раздел [dbservers]. Я решил устанавливать на эту машину mysql, для чего был создан отдельный плейбук db_playbook.yml. что бы пароли не лежали в открытом доступе использовал ansible vault и занес файл с зашифрованными паролями в .gitignore. В test.yml была добавлена проверка состояния службы mysql`


**db_playbook.yml**

```
---
- name: Installing and configuring a MySQL server
  hosts: dbservers
  become: true

  vars:
    mysql_user: root
    mysql_config:
      column_case_sensitive: true 
  vars_files:
    - group_vars/dbservers.yml.enc
  tasks:
   

    - name: Configuring the column_case_ensitive parameter
      community.mysql.mysql_variables:  
        login_user: "{{ mysql_user }}"
        login_password: "{{ mysql_user_password }}"
        variable: "lower_case_table_names"
        value: "0"
      when: mysql_config.column_case_sensitive | bool

    - name: Restarting MySQL to apply settings
      service:
        name: mysql
        state: restarted

    - name: Checking the current settings
      command: mysql -NBe "SHOW VARIABLES LIKE 'lower_case_table_names'"
      register: case_sensitive_check
      changed_when: false

    - name: Displaying the settings status
      debug:
        msg: "Register-dependent mode: {{ case_sensitive_check.stdout_lines }}"

    - name: Creating a database
      community.mysql.mysql_db:
        name: mydatabase
        state: present
        login_user: "{{ mysql_user }}"
        login_password: "{{ mysql_user_password }}"

    - name: Creating a user with privileges
      community.mysql.mysql_user:
        name: myuser
        password: "{{ mysql_user_password }}"
        priv: "mydatabase.*:ALL"
        host: '%'  
        login_user: "{{ mysql_user }}"
        login_password: "{{ mysql_user_password }}"

```
`Скриншоты`

![Скриншот 1](https://github.com/noisy441/7-03/blob/main/img/img5.png)`

test.yml

```
---
- name: test
  gather_facts: false
  hosts: webservers
  vars:
    ansible_ssh_user: user
  become: yes

  pre_tasks:
    - name: Validating the ssh port is open and
      wait_for:
        host: "{{ (ansible_ssh_host|default(ansible_host))|default(inventory_hostname) }}"
        port: 22
        delay: 5
        timeout: 300
        state: started
        search_regex: OpenSSH

  tasks:
    - name: create test file
      copy:
        dest: /tmp/test
        content: "success"

- hosts: dbservers
  gather_facts: false
  become: true
  tasks:
    - name: Checking the MySQL service status
      ansible.builtin.systemd:
        state: started
        name: mysql
      register: mysql_status

    - name: Service status output
      debug:
        var: mysql_status.state 
```

`Скриншоты`

![Скриншот 1](https://github.com/noisy441/7-03/blob/main/img/img6.png)`


---

### Решение 3.1

`Провел настройку yc tools по инструкции и добавил в конец файла ~/.bashrc команду export YC_TOKEN=$(yc iam create-token). Запустил terragorm в том же окне, инфраструктура проверилась и так как была уже создана проверка прошла успешно. Далее командой terraform destroy инфраструктура была удалена.`


![Скриншот 1](https://github.com/noisy441/7-03/blob/main/img/img7.png)`

![Скриншот 2](https://github.com/noisy441/7-03/blob/main/img/img8.png)`

