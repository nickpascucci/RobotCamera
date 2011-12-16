CXX = g++
CC_OPTS = -Wall -ggdb
LIBS = -lboost_system -ljpeg -lpthread
LIB_PATH = 
INCLUDES = 

all: capture preprocess

capture: capture.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) capture.cpp -o capture

preprocess: preprocess.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) preprocess.cpp -o preprocess

clean: 
	rm capture preprocess *.o *.d 
