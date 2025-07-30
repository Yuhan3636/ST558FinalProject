# Dockerfile

# 1) Start from the tidyverse image (it includes littler & R tools)
FROM rocker/tidyverse:4.3.1

# 2) Install system libs needed by httpuv/jsonlite/etc.
RUN apt-get update && \
    apt-get install -y libssl-dev libcurl4-openssl-dev libxml2-dev && \
    rm -rf /var/lib/apt/lists/*

# 3) Install plumber, caret, and conflicted using install2.r
RUN install2.r --error plumber caret conflicted

WORKDIR /app

# 4) Copy your API script and data (case‑sensitive)
COPY api.R .
COPY diabetes_012_health_indicators_BRFSS2015.csv .

EXPOSE 8000

# 5) Launch the API immediately via Rscript
CMD ["Rscript","-e","plumber::plumb('api.R')$run(host='0.0.0.0',port=8000)"]
