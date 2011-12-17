CXX = g++
CC_OPTS = -Wall -ggdb
LIBS = -lboost_system -lpthread -lMagick++
LIB_PATH = 
INCLUDES = -I/usr/include/ImageMagick

all: capture preprocess configure

capture: capture.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) capture.cpp -o capture

preprocess: preprocess.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) preprocess.cpp -o preprocess

configure: configure.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) configure.cpp -o configure

clean: 
	rm capture preprocess *.o *.d 
