To download the source code of all services, run:

* `./install.sh`

To start both control plane and node agents:

* [optional] If you're using MacOS, replace 
    
    `export $(grep -v '^#' .env | xargs -d '\n')`
    
    with
    
    `export $(grep -v '^#' .env | gxargs -d '\n')`
    
    in *start.sh* and *stop.sh* (line 2)

*  `./start.sh`

To stop everything:

*  `./stop.sh`
