Supported tags and respective `Dockerfile` links:  
・latest ([docker/runtime/0.4/Dockerfile](https://github.com/pottava/hubots/blob/master/docker/runtime/Dockerfile))  
・0.4 ([docker/runtime/0.4/Dockerfile](https://github.com/pottava/hubots/blob/master/docker/runtime/Dockerfile))  
・0.4-codegen ([docker/generator/0.4/Dockerfile](https://github.com/pottava/hubots/blob/master/docker/generator/Dockerfile))  

## Usage

### To configure a Hubot application & generate dependencies

`docker run --rm -it -v $(pwd):/app pottava/hubot:0.4-codegen`

### To run the hubot

`docker run --rm -it -v $(pwd):/app pottava/hubot:0.4`
