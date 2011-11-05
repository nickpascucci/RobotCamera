APP_NAME = jpegcap
SRC = jpeg.cpp
CXX = g++
CC_OPTS = -Wall -o $(APP_NAME)
LIBS = -lboost_system
LIB_PATH = -L/usr/lib/

all: jpeg

jpeg:
	$(CXX) $(CC_OPTS) $(LIBS) $(LIB_PATH) $(SRC) 

clean: 
	rm $(APP_NAME)
