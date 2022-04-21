FROM ubuntu:latest

COPY . .

ENTRYPOINT ["/.get-repo-statistics.sh"]