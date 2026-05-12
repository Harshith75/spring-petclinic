FROM tomcat:9.0
COPY $WORKSPACE/target/*.war /usr/local/tomcat/webapps/
EXPOSE 8080

