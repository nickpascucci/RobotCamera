CXX = g++
CC_OPTS = -Wall -ggdb -pthread
LIBS = -lboost_system -lMagick++
LIB_PATH = 
ARM_LIB_PATH = -L/home/nick/dev/arm/lib/ImageMagick/lib -L/home/nick/dev/arm/lib/boost_1_48_0/stage/lib
INCLUDES = -I/usr/include/ImageMagick
ARM_INCLUDES = -I/home/nick/dev/arm/lib/ImageMagick/include -I/home/nick/dev/arm/lib/boost_1_48_0

all: capture preprocess configure camtool

capture: capture.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) capture.cpp -o capture

preprocess: preprocess.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) preprocess.cpp -o preprocess

configure: configure.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) configure.cpp -o configure

camtool: camtool.cpp
	$(CXX) $(CC_OPTS) $(INCLUDES) $(LIBS) $(LIB_PATH) camtool.cpp -o camtool

camtool-arm: camtool.cpp
	$(CXX) $(CC_OPTS) $(ARM_INCLUDES) camtool.cpp -o camtool-arm $(LIBS) $(ARM_LIB_PATH)

clean: 
	rm capture preprocess *.o *.d 
