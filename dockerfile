FROM alpine:3.10

RUN apk add --update nodejs npm git mysql
RUN addgroup -S node && adduser -S node -G node
WORKDIR /home/node/

COPY runapp.sh /home/node
RUN chmod +x /home/node/runapp.sh

USER node

# Start the application
CMD ["/home/node/runapp.sh"]