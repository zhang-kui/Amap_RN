/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React, {Component} from 'react';
import {Platform, StyleSheet, Text, View, Image, Alert, TouchableOpacity , NativeModules} from 'react-native';

import { MapView, Marker, Polyline, Polygon } from 'react-native-amap3d';

// RNBridgeModule就是原生中写的那个类
var Push = NativeModules.RNBridgeModule;

export default class App extends Component<Props> {
  constructor(props) {
    super(props);
    this.state = {
      /**
       * 地图类型
       * - standard: 标准地图
       * - satellite: 卫星地图
       * - navigation: 导航地图
       * - night: 夜间地图
       * - bus: 公交地图
       */
      mapTypeArr: ['standard','satellite','navigation','night','bus'],
      mapType: 0,
      showsTraffic: true,
      showsLocationButton: true,
      zoomLevel: 16,
      mapCenter: {
        latitude: 30.546994,
        longitude: 114.292862,
      },
      markWanDa: {
        latitude: 30.506917,
        longitude: 114.173768,
      },
      markMsg: {
        latitude: 30.546994,
        longitude: 114.292862,
      },
      line1: [
        {
          latitude: 30.506917,
          longitude: 114.173768,
        },
        {
          latitude: 30.546994,
          longitude: 114.292862,
        },
      ],
      line2: [
        {
          latitude: 30.506917,
          longitude: 114.173768,
        },
        {
          latitude: 30.466917,
          longitude: 114.173768,
        },
        {
          latitude: 30.546994,
          longitude: 114.222862,
        },
        {
          latitude: 30.546994,
          longitude: 114.292862,
        },
      ],
      coordinates: [
        {
          latitude: 39.806901,
          longitude: 116.397972,
        },
        {
          latitude: 39.806901,
          longitude: 116.297972,
        },
        {
          latitude: 39.906901,
          longitude: 116.397972,
        },
      ]

    };
  }

  _onPress = () => Alert.alert('Polyline onPress');

  _jumpToNative = () => {
    console.log('@@@开始导航！！！');
    // RNOpenOneVC这个也是写在原生里面的
    Push.RNOpenNative('{x:1,y:2}');
  };

  _animatedToZGC = () => {
    this.mapView.animateTo({
      tilt: 45,
      rotation: 90,
      zoomLevel: 18,
      coordinate: {
        latitude: 30.546994,
        longitude: 114.292862,
      }
    })
  };

  _animatedToTAM = () => {
    this.mapView.animateTo({
      tilt: 0,
      rotation: 0,
      zoomLevel: 16,
      coordinate: {
        latitude: 39.90864,
        longitude: 116.39745,
      }
    })
  };

  render() {
    const { mapCenter, markWanDa, markMsg, line1, line2, coordinates } = this.state;
    return (
      <View style={styles.body}>
        <MapView
          style={styles.container}
          ref={ref => this.mapView = ref}
          // 设置地图中心
          coordinate={{
            latitude: mapCenter.latitude,
            longitude: mapCenter.longitude,
          }}
          mapType={this.state.mapTypeArr[this.state.mapType]}
          showsTraffic={this.state.showsTraffic}
          showsLocationButton={this.state.showsLocationButton}
          zoomLevel={this.state.zoomLevel}
          // 启用定位并监听定位事件
          locationEnabled
          // 定位间隔(ms)，默认 2000 @platform android
          locationInterval={3000}
          //  定位的最小更新距离 @platform ios
          distanceFilter={10}
          onLocation={({nativeEvent}) => {
            console.log(`定位坐标：${nativeEvent.latitude}, ${nativeEvent.longitude}`);
            this.setState({
              mapCenter: {
                latitude: nativeEvent.latitude,
                longitude: nativeEvent.longitude,
              },
            });
          }}
        >
          {/*设置地图标记*/}
          <Marker
            draggable
            title='万达广场(武汉经开店)'
            onDragEnd={({nativeEvent}) =>
              console.log(`${nativeEvent.latitude}, ${nativeEvent.longitude}`)}
            coordinate={{
              latitude: markWanDa.latitude,
              longitude: markWanDa.longitude,
            }}/>
          {/*自定义标记图片及信息窗体*/}
          <Marker
            title='自定义 View'
            icon={() =>
              <View>
                <Image source={require('./res/00.png')}></Image>
              </View>
            }
            centerOffset={{x: 0, y: -18}}
            coordinate={{
              latitude: markMsg.latitude,
              longitude: markMsg.longitude,
            }}
          >
            <View style={styles.customInfoWindow}>
              <Text style={styles.customInfoTxt}>武汉长江大桥位于湖北省武汉市武昌区蛇山和汉阳龟山之间，是万里长江上的第一座大桥，也是新中国成立后在长江上修建的第一座公铁两用桥，被称为“万里长江第一桥”。武汉长江大桥建成伊始即成为武汉市的标志性建筑。</Text>
            </View>
          </Marker>
          {/*划线*/}
          <Polyline
            dashed
            width={5}
            color='green'
            coordinates={line1}/>
          <Polyline
            gradient
            width={5}
            colors={['#f44336', '#2196f3', '#4caf50']}
            onPress={this._onPress}
            coordinates={line2}/>
          {/*多边形*/}
          <Polygon
            strokeWidth={5}
            strokeColor='rgba(0, 0, 255, 0.5)'
            fillColor='rgba(255, 0, 0, 0.5)'
            coordinates={coordinates}/>
        </MapView>

        <View style={styles.buttons}>
          <View style={styles.button}>
            <TouchableOpacity onPress={this._animatedToZGC}>
            <Text style={styles.text}>武汉长江大桥</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.button}>
            <TouchableOpacity onPress={this._animatedToTAM}>
              <Text style={styles.text}>北京天安门</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.button}>
            <TouchableOpacity onPress={() => this.setState({mapType: this.state.mapType < 4 ? this.state.mapType+1 : 0})}>
              <Text style={styles.text}>地图类型</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.button}>
            <TouchableOpacity onPress={() => this.setState({zoomLevel: this.state.zoomLevel+1})}>
              <Text style={styles.text}>放大</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.button}>
            <TouchableOpacity onPress={() => this.setState({zoomLevel: this.state.zoomLevel-1})}>
              <Text style={styles.text}>缩小</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.button}>
            <TouchableOpacity onPress={() => this._jumpToNative()}>
              <Text style={styles.text}>开始路线规划</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  body: {
    flex: 1,
  },
  container: {
    flex: 1,
  },
  customInfoWindow: {
    width: 150,
    height: 133.4,
    padding: 5,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fffbe0',
  },
  customInfoTxt: {
    fontSize: 12,
    color: 'green',
  },
  buttons: {
    width: 120,
    position: 'absolute',
    top: 40,
    right: 10,
  },
  button: {
    width: 120,
    height: 40,
    marginTop: 10,
    borderRadius: 50,
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    fontSize: 16,
  },
});
