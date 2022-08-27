# odoo-master-docker
create dockerfile from source for odoo master branch on Mac M1

1、Install Docker  
2、create project folder like below  
&emsp;&emsp;odoo16--|  
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;odoo  
&emsp;&emsp;&emsp;&emsp;&emsp;--|  
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Dockerfile  
&emsp;&emsp;&emsp;&emsp;&emsp;--|  
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;entrypoint.sh  
&emsp;&emsp;&emsp;&emsp;&emsp;--|  
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;odoo.conf  
&emsp;&emsp;&emsp;&emsp;&emsp;--|  
&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;wait-for-psql.py  
3、clone odoo master branch into [odoo] folder  
4、open folder [odoo16] with Visual Studio Code, must install docker extension first  
5、Build odoo image with docker name [odoo16]  
6、Pull postgres image and run  
&emsp;&emsp;docker run -d -p 5432:5432 -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name db postgres:13  
7、Run odoo image  
&emsp;&emsp;docker run -p 8069:8069 --name odoo16 --link db:db -t odoo16  
8、open http://localhost:8069 with browser  
