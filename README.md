# Somebody Else's Problem

[![License](https://img.shields.io/github/license/MMCWonko/SomebodyElsesProblem.svg)](https://img.shields.io/github/license/MMCWonko/SomebodyElsesProblem.svg)

From _Life, the Universe and Everything_ by Douglas Adams:

> Somebody Else's Problem field, or SEP, is a cheap, easy, and staggeringly useful way of safely protecting something from unwanted eyes. It can run almost indefinitely on a torch (flashlight)/9 volt battery, and is able to do so because it utilises a person's natural tendency to ignore things they don't easily accept, like, for example, aliens at a cricket match. Any object around which an S.E.P. is applied will cease to be noticed, because any problems one may have understanding it (and therefore accepting its existence) become Somebody Else's. An object becomes not so much invisible as unnoticed.
>
> A perfect example of this would be a ship covered in an SEP field at a cricket match. A starship taking the appearance of a large pink elephant is ideal, because you can see it, but because it is so inconceivable, your mind can't accept it. Therefore it can't exist, thus ignoring it comes naturally.
>
> A S.E.P. can work in much the same way in dangerous or uninhabitable environments. Any problem which may present itself to a person inside an S.E.P. (such as not being able to breathe, due to a lack of atmosphere) will become Somebody Else's.
>
> An S.E.P. can be seen if caught by surprise, or out of the corner of one's eye.

## Wait what?

This is a small ruby script that Wonko files into a proper structure for a static webserver to point to.

There are two reasons for the name: First, tasks done by this script don't really fit into any other Wonko-related project, thus the tasks are "Somebody [this script's] Else's Problem". Secondly (and more of an after thought, trying to shoehorn the above quote into the project) this script should be mostly invisible to most people, unless you know what you're looking for.

## Usage

### With docker

Install [docker](https://docker.com/) and run

    $ docker run -d -v /path/to/in:/usr/src/app/in -v /path/to/out:/usr/src/app/out -p 4242:80 02jandal/somebody_elses_problem

This will download the `02jandal/somebody_elses_problem` image and run it. Replace `/path/to/in` and `/path/to/out` with paths to directories on your local filesystem. `/path/to/in` should be same as `/path/to/out` for the 
[WonkoTheSane](https://github.com/MMCWonko/WonkoTheSane) image (WTS produces, SEP consumes). You could also directly link the two containers together, in that case you wouldn't get access to those two directories from the host machine.

Replace `4242` by the port on which to listen for [uploads](#uploading), or omit the entire `-p` option if you do not want to support uploading.

If you do not wish the container to run in the background, for example because you want to be able to view the log, remove the `-d` option.

See the documentation for the [docker run](https://docs.docker.com/reference/run/) command for all possible options.

### Without docker

    $ git clone git@github.com:MMCWonko/SomebodyElsesProblem.git
    $ cd SomebodyElsesProblem
    $ bundle install
    $ bundle exec ./sep.rb --indir /path/to/in --outdir /path/to/out --server 4242

Replace `/path/to/in` and `/path/to/out` with paths to directories on your local filesystem. `/path/to/in` should be same as the `/path/to/out` of [WonkoTheSane](https://github.com/MMCWonko/WonkoTheSane) image (WTS produces, SEP consumes).

Replace `4242` by the port on which to listen for [uploads](#uploading), or omit the entire `--server` option if you do not want to support uploading.

### Uploading

The script as a built-in webserver. It is activated by giving the `--server <PORT>` option when manually invoking, or by binding port `80` of the container when using the docker image. Sending a POST or PUT request to `/upload` with either the contents of a WonkoFile or WonkoVersion in either the body, or as a file upload in the "file" parameter will put the file into the input directory, meaning it will get processed. This script does not, and will not, do anything more than that, for authorization etc. you'll have to use a reverse proxy or similar.
