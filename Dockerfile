FROM pottava/hubot:0.4

ENV HUBOT_SLACK_TOKEN=token \
    HUBOT_SLACK_TEAM=team \
    HUBOT_SLACK_BOTNAME=name \
    HUBOT_HEROKU_KEEPALIVE_URL=0

ADD slack /app

RUN npm install "coffee-script@1.12.7" \
    && npm install "hubot-slack@4.4.0" \
    && rm -rf /root/.npm \
    && find / -depth -type d -name test* -exec rm -rf {} \; \
    && find / -depth -type f -name *.md -exec rm -f {} \; \
    && find / -depth -type f -name *.yml -exec rm -f {} \;

CMD ["/app/bin/hubot", "--name", "hubot", "--adapter", "slack"]
