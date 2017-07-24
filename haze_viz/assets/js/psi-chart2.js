"use strict";

    var conversion=[
        {psi:0,pm2_5:0},
        {psi:50,pm2_5:12},
        {psi:100,pm2_5:55},
        {psi:200,pm2_5:150},
        {psi:300,pm2_5:250},
        {psi:400,pm2_5:350},
        {psi:500,pm2_5:500}
    ];

  var locations = [
    {id:'north', latlng: [1.398761, 103.825329]},
    {id:'west', latlng:[1.357575, 103.707226]},
    {id:'central', latlng: [1.3411, 103.828076]},
    {id:'east', latlng: [1.343846, 103.965405]},
    {id:'south', latlng: [1.283437, 103.828076]}
  ];
    
    function getColor(psi) {
        if (psi < 51) {
            return '#479b02';
        } else if (psi < 101) {
            return '#006fa1';
        } else if (psi < 201) {
            return '#ffce03';
        } else if (psi < 301) {
            return '#ffa800';
        } else {
            return '#d60000';
        }
    }
    
    function computeEstimatedPSI(pm2_5){
        for(var i=1;i<conversion.length;++i){
            if(pm2_5<=conversion[i].pm2_5){
                return Math.round((conversion[i].psi-conversion[i-1].psi)/(conversion[i].pm2_5-conversion[i-1].pm2_5)*(pm2_5-conversion[i-1].pm2_5)+conversion[i-1].psi);
            }
        }
        return 0;
    }
    
    function getDate(offset){
        var today = new Date();
        
        var calculatedDate = new Date();
        calculatedDate.setDate(calculatedDate.getDate() - offset);
        
        var dd = calculatedDate.getDate();
        var mm = calculatedDate.getMonth()+1; //January is 0!
        var yyyy = calculatedDate.getFullYear();
        if(dd<10){
            dd='0'+dd;
        } 
        if(mm<10){
            mm='0'+mm;
        }
        return yyyy + '-' + mm + '-' + dd;
    }

    function get24hPSI(today, yesterday){
        var readingsToday;
        var readingsYesterday;
        $.when(
            $.ajax({
                type: "GET",
                url: "https://api.data.gov.sg/v1/environment/pm25?date=" + today,
                headers: { "api-key": "***REMOVED***" },
                processData: false,
                error: function (xhr, ajaxOptions, thrownError){
                    console.log(xhr.status);
                    console.log(thrownError);
                },
                success: function(data,textStatus,jqXHR){
                    readingsToday = data.items;
                }
            }),
            $.ajax({
                type: "GET",
                url: "https://api.data.gov.sg/v1/environment/pm25?date=" + yesterday,
                headers: { "api-key": "***REMOVED***" },
                processData: false,
                error: function (xhr, ajaxOptions, thrownError){
                    console.log(xhr.status);
                    console.log(thrownError);
                },
                success: function(data,textStatus,jqXHR){
                    readingsYesterday = data.items;
                }
            })
        ).then( function(){
            
            var allReadings = readingsYesterday.concat(readingsToday);
            var values24h = allReadings.slice(allReadings.length - 23, allReadings.length);
            
            //var json = [];
            var jsonWest = {};
            jsonWest.region = "west";
            jsonWest.timestamp = [];
            var jsonEast = {};
            jsonEast.region = "east";
            jsonEast.timestamp = [];
            var jsonNorth = {};
            jsonNorth.region = "north";
            jsonNorth.timestamp = [];
            var jsonSouth = {};
            jsonSouth.region = "south";
            jsonSouth.timestamp = [];
            var jsonCentral = {};
            jsonCentral.region = "central";
            jsonCentral.timestamp = [];
            
            values24h.forEach(function(record) 
            {
                var westValue = computeEstimatedPSI(record.readings.pm25_one_hourly.west);
                var eastValue = computeEstimatedPSI(record.readings.pm25_one_hourly.east);
                var northValue = computeEstimatedPSI(record.readings.pm25_one_hourly.north);
                var southValue = computeEstimatedPSI(record.readings.pm25_one_hourly.south);
                var centralValue = computeEstimatedPSI(record.readings.pm25_one_hourly.central);
                
                var dateValue = record.timestamp.substr(0,10);
                var hourValue = record.timestamp.substr(11,5);
                jsonWest.timestamp.push({hour: hourValue, date: dateValue, PSIvalue: westValue});
                jsonEast.timestamp.push({hour: hourValue, date: dateValue, PSIvalue: eastValue});
                jsonNorth.timestamp.push({hour: hourValue, date: dateValue, PSIvalue: northValue});
                jsonSouth.timestamp.push({hour: hourValue, date: dateValue, PSIvalue: southValue});
                jsonCentral.timestamp.push({hour: hourValue, date: dateValue, PSIvalue: centralValue});
            });
            
            createChart("chartContainer", jsonWest.timestamp, jsonEast.timestamp, jsonNorth.timestamp, jsonSouth.timestamp, jsonCentral.timestamp);
            drawMap(values24h[0]);
            
        });
    }

    function createChart(container, readingsWest, readingsEast, readingsNorth, readingsouth, readingsCentral) {
        
        var processed_json_west = new Array();
        var processed_json_east = new Array();
        var processed_json_north = new Array();
        var processed_json_south = new Array();
        var processed_json_central = new Array();
        
        // Populate series
        
        for (var i = 0; i < readingsWest.length; i++){
            processed_json_west.push([readingsWest[i].hour, readingsWest[i].PSIvalue]);
            processed_json_east.push([readingsEast[i].hour, readingsEast[i].PSIvalue]);
            processed_json_north.push([readingsNorth[i].hour, readingsNorth[i].PSIvalue]);
            processed_json_south.push([readingsouth[i].hour, readingsouth[i].PSIvalue]);
            processed_json_central.push([readingsCentral[i].hour, readingsCentral[i].PSIvalue]);
        }
     
        // draw chart
        var chart = Highcharts.chart(container, {
            chart: {
                type: "column"
            },
            title: {
                text: ""
            },
            xAxis: {
                type: 'category',
                labels: {
                    rotation: -45
                },
                allowDecimals: false,
                title: {
                    text: ""
                }
            },
            yAxis: {
                title: {
                    text: ""
                }
            },
            plotOptions: {
                column: {
                    zones: [{
                        value: 51, // Values up to 51 (not including) ...
                        color: '#479b02' // ... have the color green.
                    },{
                        value: 101, // Values up to 101 (not including) ...
                        color: '#006fa1' // ... have the color blue.
                    },{
                        value: 201, // Values up to 201 (not including) ...
                        color: '#FFCE03' // ... have the color yellow.
                    },{
                        value: 301, // Values up to 301 (not including) ...
                        color: '#FFA800' // ... have the color orange.
                    },{
                        color: '#d60000' // Values from 301 (including) and up have the color red
                    }]
                },
                series: {
                    events: {
                        show: function () {
                            var chart = this.chart,
                                series = chart.series,
                                i = series.length,
                                otherSeries;
                            while (i--) {
                                otherSeries = series[i];
                                if (otherSeries != this && otherSeries.visible) {
                                    otherSeries.hide();
                                }
                            }
                        },
                        legendItemClick: function() {
                            if(this.visible){
                                 return false;
                            }
                        }
                    }
                }
            },
            series: [{
                name: 'West',
                data: processed_json_west,
                colorByPoint: true
            },{
                name: 'East',
                data: processed_json_east,
                visible: false,
                colorByPoint: true
            },{
                name: 'North',
                data: processed_json_north,
                visible: false,
                colorByPoint: true
            },{
                name: 'South',
                data: processed_json_south,
                visible: false,
                colorByPoint: true
            },{
                name: 'Central',
                data: processed_json_central,
                visible: false,
                colorByPoint: true
            }]
        }); 
    }
    
    function drawMap(data) {
    //Initialize global variables
    var mapWidth = $("#map").width();

    // Mobile
    if ($("#map").width() < 768) {
        var mapHeight = 0.5 * mapWidth;
    // Tablets and small desktops
    }else if ($("#map").width() < 1200) {
        var mapHeight = 0.4 * mapWidth;
    // Large desktops
    } else {
        var mapHeight = 0.3 * mapWidth;
    }
    
    $("#map").css("width", mapWidth).css("height", mapHeight);
            
    var maxBounds = L.latLngBounds(L.latLng(1.461, 103.51), L.latLng(1.209, 104.11));

    // Need to fix CSS properties before leaflet map properties
    if ($("#map").width() < 768) {
        var leafletMap = L.map('map',{
            center: [1.347833, 103.809357],
            zoom: 10,
            maxZoom: 10,
            minZoom: 10,
            zoomControl: false,
        }).setMaxBounds(maxBounds);
    }else if ($("#map").width() < 1200) {
        var leafletMap = L.map('map',{
            center: [1.347833, 103.809357],
            zoom: 11,
            maxZoom: 11,
            minZoom: 11,
            zoomControl: false,
        }).setMaxBounds(maxBounds);
    } else {
        var leafletMap = L.map('map',{
            center: [1.347833, 103.809357],
            zoom: 12,
            maxZoom: 12,
            minZoom: 12,
            zoomControl: false,
        }).setMaxBounds(maxBounds);
    }
    
    // Access token is Hishab's access token to Mapbox - to change!
    L.mapbox.accessToken = 'pk.eyJ1IjoieWl0Y2giLCJhIjoiY2oydDBid2hrMDA5bzJxcGY0OHB0aXZ3eiJ9.rxD7qRDKOyQ-_lcN6oTnkw';
    
    var mapLayer = L.tileLayer('https://api.mapbox.com/v4/mapbox.light/{z}/{x}/{y}.png?access_token=' + L.mapbox.accessToken, {
        attribution: 'Map tiles <a href="http://mapbox.com">Mapbox</a> | Map data <a href="http://openstreetmap.org">OpenStreetMap</a>',
    })

    L.control.scale().addTo(leafletMap);
    
     // Add circlemarkers
    var stations = [];
    for (var i = 0; i < locations.length; i++){
    
        var latlng = locations[i].latlng;
        var region = locations[i].id;
        var reading = data.readings.pm25_one_hourly[region];
        var rad = ($("#map").width() < 480) ?  10 : 30;
     
        stations.push(L.circleMarker(latlng,{radius: rad + reading/5, color:getColor(reading)}));

        var textLabel = L.marker(latlng, {
            icon: L.divIcon({
                className: 'map-labels',   // Set class for CSS styling
                html: computeEstimatedPSI(reading)
            }),
            zIndexOffset: 100     // Make appear above other map features
        });
        
        stations.push(textLabel);
    }    
    var stationLayer = L.layerGroup(stations);
        
    leafletMap.addLayer(mapLayer);
    leafletMap.addLayer(stationLayer);

    }
    
    $(document).ready(function() {
        get24hPSI(getDate(0),getDate(1));
    });
    