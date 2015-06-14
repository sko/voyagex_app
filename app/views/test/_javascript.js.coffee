#for key, i in Object.keys(localStorage)
#  #console.log(key)
#  document.writeln i+'. key = '+key+'<br>'
testStorageController = (initError) ->
  console.log 'StorageController initialized FileSystem with message: '+(if initError then 'FAILED' else 'OK')
  radiusMeters = VoyageX.SEARCH_RADIUS_METERS
  document.writeln 'showPois for radius '+radiusMeters+' meters<br>'
  showPois searchBounds(52.5051, 13.4164, radiusMeters)
  radiusMeters = VoyageX.SEARCH_RADIUS_METERS / 2
  document.writeln 'showPois for radius '+radiusMeters+' meters<br>'
  showPois searchBounds(52.5051, 13.4164, radiusMeters)

showPois = (searchBounds) ->
  sC.getPois (poi) ->
      if poi.lat > searchBounds.lat_south && poi.lat < searchBounds.lat_north &&
         poi.lng > searchBounds.lng_east && poi.lng < searchBounds.lng_west
        document.writeln '<font color="green">IN poi = '+JSON.stringify(poi)+'</font><br>'
        sC.delete Comm.StorageController.poiKey(poi)
        return true
      else
        document.writeln '<font color="red">IN poi = '+JSON.stringify(poi)+'</font><br>'
        return false

#sC = new Comm.StorageController(testStorageController)

testLocation = (initError) ->
  locationId = 1
  location = sC.getLocation locationId
  document.writeln 'location = '+JSON.stringify(location)+'<br>'
  sC.saveLocation {id: locationId, lat: 0, lng: 0, address: 'nowhere'}
  location = sC.getLocation locationId
  document.writeln 'location = '+JSON.stringify(location)+'<br>'
  location = sC.getLocation new String(locationId)
  document.writeln 'location = '+JSON.stringify(location)+'<br>'
  document.writeln 'bookmarks 1:<br>'
  bookmarks = sC.bookmarks (locations, locationBookmark, num, idx) ->
                  document.writeln 'locationBookmark = '+JSON.stringify(locationBookmark)+'<br>'
                  locationBookmark.text = 'testi'
                  false
  for location in bookmarks
    document.writeln 'location = '+JSON.stringify(location)+'<br>'
  document.writeln 'bookmarks 2:<br>'
  sC.bookmark locationId
  bookmarks = sC.bookmarks()
  for location in bookmarks
    document.writeln 'location = '+JSON.stringify(location)+'<br>'

sC = new Comm.StorageController(testLocation)
