"use strict";

    //Initialize global variables
    var mapVisible = true;

    var mapWidth = $("#map").width(),
        mapHeight = 0.55 * mapWidth;

    $("#map").css("height", mapHeight);
        
    var histogramWidth = $("#histogram").width(),
        legendWidth = 300;

    /*
    // Histogram parameters
    var histogramBarHeight = 100,
        histogramLeftWidth = 250,
        histogramSmallestBar = 30;
    
    // Colour domain
    var color_domain = [0, 100];

    var color = d3.scaleLinear()
        .domain(color_domain)
        .range(["#733","#3c9"]);

    var color_threshold = "#055";
        
    // Add tooltip;
    var tooltip = d3.select("body").append("div")
    .attr("class", "tooltip")
    .style("opacity", 0);  
    */
    
    var maxBounds = L.latLngBounds(L.latLng(1.461, 103.51), L.latLng(1.209, 104.11));
    
    // Mobile
    if ($(window).width() < 768) {
        var leafletMap = L.map('map',{
            center: [1.347833, 103.809357],
            zoom: 10,
            maxZoom: 10,
            minZoom: 10,
            zoomControl: false,
        }).setMaxBounds(maxBounds);
        
    // Tablets and small desktops
    }else if ($(window).width() < 1200) {
        var leafletMap = L.map('map',{
            center: [1.347833, 103.809357],
            zoom: 11,
            maxZoom: 11,
            minZoom: 11,
            zoomControl: false,
        }).setMaxBounds(maxBounds);
    
    // Large desktops
    } else {
        var leafletMap = L.map('map',{
            center: [1.347833, 103.809357],
            zoom: 12,
            maxZoom: 12,
            minZoom: 12,
            zoomControl: false,
        }).setMaxBounds(maxBounds);
    }
            
    var randomNormalPerformance = d3.randomNormal(50, 15);
    
    for (var i = 0; i < data.length; i++){
        data[i].psi = Math.round(randomNormalPerformance());
    }    
    
    // var transform = d3.geoTransform({point: projectPoint});
            
    // Assign the projection to a path
    // var path = d3.geoPath().projection(transform);
    
    // Access token is Haishab's access token to Mapbox
    L.mapbox.accessToken = 'pk.eyJ1IjoieWl0Y2giLCJhIjoiY2oydDBid2hrMDA5bzJxcGY0OHB0aXZ3eiJ9.rxD7qRDKOyQ-_lcN6oTnkw';
    
    var mapLayer = L.tileLayer('https://api.mapbox.com/v4/mapbox.light/{z}/{x}/{y}.png?access_token=' + L.mapbox.accessToken, {
        attribution: 'Map tiles <a href="http://mapbox.com">Mapbox</a> | Map data <a href="http://openstreetmap.org">OpenStreetMap</a> | Visualization <a href="htttp://www.vslashr.com">V/R</a>',
        // maxZoom: 12,
        // minZoom: 7
    })

    L.control.scale().addTo(leafletMap);
    
    
     // Add farm layer markers
    var stations = [];
    for (var i = 0; i < data.region_metadata.length; i++){
    
        //Ignore national as not plotting that data point. Data API for haze viz at https://developers.data.gov.sg/environment/psi
        if (data.region_metadata[i].name != "national") {
            var latlng = [data.region_metadata[i].label_location.latitude, data.region_metadata[i].label_location.longitude];
            var region = data.region_metadata[i].name;
            var reading = data.items[0].readings.psi_twenty_four_hourly[region];
         
            stations.push(L.circleMarker(latlng,{radius: reading}));

            var textLabel = L.marker(latlng, {
                icon: L.divIcon({
                    className: 'map-labels',   // Set class for CSS styling
                    html: reading
                }),
                zIndexOffset: 100     // Make appear above other map features
            });
            
            stations.push(textLabel);
        }
    }    
    var stationLayer = L.layerGroup(stations);
        
   if (mapVisible) { 
        leafletMap.addLayer(mapLayer);
        leafletMap.addLayer(stationLayer);
        $("#map svg").css("opacity", 0.6);
    };
        
    // Adding Leaflet layer
    var svg = d3.select(leafletMap.getPanes().overlayPane)
        .append("svg");

    svg.append("g")
        .attr("class", "leaflet-zoom-hide");
      
    //d3.select("#histogram").append("svg");
        
    // Load data before drawing
    // queue()
        // .defer(d3.json, 'assets/data/bangladesh_district_lower_rez.json')
        // .defer(d3.json, 'assets/data/bangladesh_pop.json')
        // .await(mergeDataThenDraw);


$("#layerControl").click(function() {

    if (mapVisible) {
        leafletMap.removeLayer(mapLayer);
     
        $("#map svg").css("opacity", 1);

        mapVisible = false;
        
    } else {
        leafletMap.addLayer(mapLayer);

        $("#map svg").css("opacity", 0.6);

        mapVisible = true;
    }
});


String.prototype.toProperCase = function () {
    return this.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
};

$( window ).resize(function() {
    mapWidth = $("#map").width();
    mapHeight = 0.55 * mapWidth;
    
    $("#map").css("height", mapHeight);
    
    histogramWidth = $("#histogram").width();
    //drawHistogram(data[districtIndex].properties.products);
    
    if ($(window).width() < 768) {
        $("#map_legend").hide();
    } else {
        $("#map_legend").show();
    }    
    
    //updateLegend();
    
});
