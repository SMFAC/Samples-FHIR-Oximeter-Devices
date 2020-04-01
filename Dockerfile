FROM docker.iscinternal.com/intersystems/irishealth-community:2020.1.0-latest

USER root
# https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=ADOCK_iris_iscmain
RUN mkdir /opt/app && chown irisowner:irisowner /opt/app



USER irisowner

WORKDIR /opt/app


COPY ./Setup.cls ./
COPY ./src ./src/




RUN iris start $ISC_PACKAGE_INSTANCENAME quietly EmergencyId=sys,sys && \
    /bin/echo -e "sys\nsys\n" \
            " Do ##class(Security.Users).UnExpireUserPasswords(\"*\")\n" \
            " Do ##class(Security.Users).AddRoles(\"admin\", \"%ALL\")\n" \
            " Do ##class(Security.System).Get(,.p)\n" \
            " // 2**4 = 16; this sets bit 4 to enable OS authentication for the admin user" \
            " Set p(\"AutheEnabled\")=\$zboolean(p(\"AutheEnabled\"),16,7)\n" \
            " Do ##class(Security.System).Modify(,.p)\n" \
            " Do \$system.OBJ.Load(\"/opt/app/Setup.cls\", \"ck\")\n" \
            "set sc = ##class(Setup).setUpFHIR()\n"\
            " If 'sc do \$zu(4, \$JOB, 1)\n" \
            " halt" \
    | iris session $ISC_PACKAGE_INSTANCENAME && \
    /bin/echo -e "sys\nsys\n" \
    | iris stop $ISC_PACKAGE_INSTANCENAME quietly

WORKDIR /datavol
CMD [ "-l", "/usr/irissys/mgr/messages.log" ]
