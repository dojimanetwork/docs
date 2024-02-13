FROM python:3-alpine3.14 as builder

ARG USER=1000

RUN adduser -h /usr/src/mkdocs -D -u $USER mkdocs \
&& apk add bash \
&& apk add git 

ENV PATH="${PATH}:/usr/src/mkdocs/.local/bin"

USER mkdocs
RUN mkdir -p /usr/src/mkdocs/build
WORKDIR /usr/src/mkdocs/build

RUN pip install --upgrade pip

RUN pip install pymdown-extensions \
&& pip install mkdocs \
&& pip install mkdocs-material \
&& pip install mkdocs-rtd-dropdown \
&& pip install mkdocs-git-revision-date-plugin \
&& pip install mkdocs-git-revision-date-localized-plugin \
&& pip install mkdocs-blog-plugin \
&& pip3 install mkdocs-blogging-plugin

COPY . .

RUN pip install -r requirements.txt --no-cache-dir
# The following line is bcause of mkdocs build error: Unable to read git logs of
RUN git config --global --add safe.directory '*'

RUN /usr/src/mkdocs/.local/bin/mkdocs build --clean --site-dir /usr/src/mkdocs/build/srv

FROM nginx:alpine
COPY --from=builder /usr/src/mkdocs/build/srv /var/www/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

ENTRYPOINT ["mkdocs"]
EXPOSE 83
CMD ["nginx", "-g", "daemon off;"]