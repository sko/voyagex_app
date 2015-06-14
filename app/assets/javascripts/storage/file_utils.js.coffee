if window.Comm?
  window.Comm.FileUtils = {}
else
  window.Comm = { FileUtils: {} }

class window.Comm.FileUtils
 
  @_SINGLETON = null
  @_FS = null

  #constructor: (requestedBytes, tileDB, tileImageContentType, storedFilesAreBase64, fsInitCB) ->
  constructor: (requestedBytes, tileImageContentType, storedFilesAreBase64, fsInitCB) ->
    FileUtils._SINGLETON = this
    #@_tileDB = tileDB
    fU = this
    @_tileLoadQueue = {}
    @_tileImageContentType = tileImageContentType
    @_storedFilesAreBase64 = storedFilesAreBase64
    @_grantedBytes = 0
    @_dirReaders = {}
    try
      fileAPISupport = `navigator.webkitPersistentStorage !== undefined`
    catch error
      fileAPISupport = false
    console.log('FileUtils.constructor - fileAPISupport = '+fileAPISupport)
    if fileAPISupport
      window.webkitStorageInfo.queryUsageAndQuota(webkitStorageInfo.PERSISTENT, 
          (used, remaining) ->
              console.log("Used quota: " + used + ", remaining quota: " + remaining)
          , (e) ->
              console.log('Error', e)
          )
      # @deprecated
      #window.webkitStorageInfo.queryUsageAndQuota(webkitStorageInfo.PERSISTENT,  (used, remaining) ->
      #window.webkitStorageInfo.requestQuota(webkitStorageInfo.PERSISTENT, requestedBytes, (grantedBytes) ->
      navigator.webkitPersistentStorage.requestQuota(requestedBytes, (grantedBytes) ->
          #window.webkitRequestFileSystem(PERSISTENT, grantedBytes, FileUtils.onInitFs, FileUtils.onFsError)
          # @deprecated
          window.webkitRequestFileSystem(webkitStorageInfo.PERSISTENT, grantedBytes, (fs) ->
                console.log('filesystem zugang')
                FileUtils.instance()._dirReaders = { parent: null, path: '/', entry: fs.root, reader: fs.root.createReader(), entries: {} }
                FileUtils._FS = fs
                fsInitCB false
            ,
            (e) ->
                console.log('kein filesystem zugang')
                fsInitCB true
            )
        , (e) ->
            console.log('Error', e); 
            fsInitCB true
        )
    else
      fsInitCB true

  clearCache: (flags = {tiles: null, poiNotes: null, users: null}) ->
    if flags.tiles? && flags.tiles
      for dirName in VoyageX.MapControl.instance()._offlineZooms
        this._removeDirectory dirName
    if flags.poiNotes? && flags.poiNotes
      this._removeDirectory 'poiNotes'
    if flags.users? && flags.users
      this._removeDirectory 'users'

  deleteAttachment: (poiNoteId, callback) ->
    @_dirReaders.entry.getFile '/poiNotes/attachments/'+poiNoteId, {}, (fileEntry) ->
        fileEntry.remove (e) ->
              console.log 'clear: deleted file /poiNotes/attachments/'+poiNoteId
              if callback?
                callback 'ok: '+poiNoteId
            , (error) ->
                console.log 'clear: error when deleting /poiNotes/attachments/'+poiNoteId+': '+error
                if callback?
                  callback 'error: '+poiNoteId+' - '+error

  clear: (flags = {tilePaths: [], poiNoteIds: [], userIds: []}, callback = null) ->
    if flags.tilePaths?
      for tilePath in tilePaths
        `TODO`
    if flags.poiNoteIds?
      for poiNoteId in flags.poiNoteIds
        this.deleteAttachment poiNoteId, callback
    if flags.userIds?
      for userId in userIds
        `TODO`

  resolvedCB: (tileKey) ->
    delete this._tileLoadQueue[tileKey]

  _removeDirectory: (dirName) ->
    @_dirReaders.entry.getDirectory(dirName, {}, (dirEntry) ->
            dirEntry.removeRecursively(() ->
                console.log('removing directory '+dirName+' ...')
              , (e) ->
                console.log('error when removing directory '+dirName+': ', e)
              )
          , (e) ->
              console.log('error when removing directory '+dirName+': ', e)
          )

  _saveTileFile: (xYZ, fileIdx, dirReader, data, deferredModeParams) ->
    fU = FileUtils.instance()
    path = dirReader.path+'/'+xYZ[fileIdx]
    dirReader.entry.getFile(xYZ[fileIdx], {}, (fileEntry) ->
        #unless dirReader.entries[xYZ[fileIdx]]?
        #  dirReader.entries[xYZ[fileIdx]] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
        #
        # file already exists - would be overwritten (@see _saveFile)
        #
        # TODO - what is this for? is this call necessary?
        #fU._storeTileAsFile xYZ, dirReader, null, deferredModeParams
        `;`
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          # new fU._writeFile fileName, dirReader, data, deferredModeParams
          dirReader.entry.getFile(xYZ[fileIdx], {create: true}, (fileEntry) ->
                fileEntry.createWriter((fileWriter) ->
                  fileWriter.onwriteend = (e) ->
                      console.log('Write completed.')
                      if deferredModeParams.fileStatusCB?
                        deferredModeParams.fileStatusCB deferredModeParams, true
                      deferredModeParams.deferred.resolve fileEntry.toURL(fU._tileImageContentType)
                      deferredModeParams.deferred = null
                      storeKey = Comm.StorageController.tileKey(xYZ)
                      delete fU._tileLoadQueue[storeKey]
                      sC = APP.storage()
                      tileMeta = localStorage.getItem 'comm.tiles.tileMeta'
                      if tileMeta == null
                        sC._tileMeta = { tilesByteSize: 0, numTiles: 0 }
                      else
                        sC._tileMeta = JSON.parse(tileMeta)
                      #sC._tileDB[storeKey] = data.properties.data
                      sC._tileMeta.numTiles = sC._tileMeta.numTiles+1
                      sC._tileMeta.tilesByteSize = sC._tileMeta.tilesByteSize+data.properties.data.size
                      localStorage.setItem 'comm.tiles.tileMeta', JSON.stringify(sC._tileMeta)
                      APP.view().showCacheStats(sC._tileMeta.numTiles, sC._tileMeta.tilesByteSize)
                  fileWriter.onerror = (e) ->
                      console.log('Write failed: ' + e.toString())
                      if deferredModeParams.fileStatusCB?
                        deferredModeParams.fileStatusCB deferredModeParams, true
                      #deferredModeParams.deferred.resolve deferredModeParams.tileUrl
                      deferredModeParams.deferred.resolve VoyageX.MapControl.notInCacheImage(xYZ[0], xYZ[1], xYZ[2])
                      deferredModeParams.deferred = null
                      delete fU._tileLoadQueue[Comm.StorageController.tileKey(xYZ)]
                  console.log('saving file: '+path)
                  fileWriter.write(new Blob([data.properties.data], {type: fU._tileImageContentType}))
                  # text-files
                  #fileWriter.write(data.properties.data)
                , (e) ->
                    console.log('_saveTileFile - '+e+' when trying to WRITE file '+path)
                )
            , (e) ->
                console.log('_saveTileFile - '+e+' when trying to SAVE file '+path)
            )
        else
          console.log('_saveTileFile - '+e+' when trying to STORE file '+path)
          fU._storeTileAsFile xYZ, dirReader, null, deferredModeParams
      )

  # '/'+xYZ[2]+'/'+xYZ[0]+'/'+xYZ[1]
  _getTileDirectory: (xYZ, nextDirIdx, dirReader, data, deferredModeParams, firstCall = true) ->
    fU = FileUtils.instance()
    path = (if dirReader.parent == null then '' else dirReader.path)+'/'+xYZ[nextDirIdx]
    dirReader.entry.getDirectory(xYZ[nextDirIdx], {}, (fileEntry) ->
        #console.log('found directory: '+path)
        unless dirReader.entries[xYZ[nextDirIdx]]?
          dirReader.entries[xYZ[nextDirIdx]] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
        fU._storeTileAsFile xYZ, dirReader.entries[xYZ[nextDirIdx]], data, deferredModeParams
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          console.log('creating tile-directory: '+path)
          dirReader.entry.getDirectory(xYZ[nextDirIdx], {create: true, exclusive: true}, (fileEntry) ->
              unless dirReader.entries[xYZ[nextDirIdx]]?
                dirReader.entries[xYZ[nextDirIdx]] = { parent: dirReader, path: path, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
              fU._storeTileAsFile xYZ, dirReader.entries[xYZ[nextDirIdx]], data, deferredModeParams
            , (e) ->
              if (e.code == FileError.NOT_FOUND_ERR) 
                console.log('_getTileDirectory - No such file: '+path)
              else
                # it's likely that directory has been created meanwhile by other request
                if firstCall
                  #console.log('_getTileDirectory - '+e+' when trying to CREATE directory / trying one more READ: '+path)
                  return fU._getTileDirectory xYZ, nextDirIdx, dirReader, data, deferredModeParams, false
                else
                  console.log('_getTileDirectory - '+e+' when trying to CREATE directory '+path)
              fU._storeTileAsFile xYZ, dirReader, data, deferredModeParams, nextDirIdx
            )
        else
          console.log('_getTileDirectory - '+e+' when trying to READ directory '+path)
          fU._storeTileAsFile xYZ, dirReader, data, deferredModeParams, nextDirIdx
      )

  _storeTileAsFile: (xYZ, parentDirReader, data, deferredModeParams, failedIndex = -1) ->
    if failedIndex != -1
      console.log('error: failedIndex = '+failedIndex+' for '+xYZ)
    else if parentDirReader == null
      this._getTileDirectory xYZ, 2, @_dirReaders, data, deferredModeParams
    else if parentDirReader.parent.parent == null
      this._getTileDirectory xYZ, 0, parentDirReader, data, deferredModeParams
    else if data != null
      this._saveTileFile xYZ, 1, parentDirReader, data, deferredModeParams

  storeTile: (xYZ, data, promise = null, deferredModeParams = null) ->
    if promise != null
      # @see getTile
      unless @_tileLoadQueue[Comm.StorageController.tileKey(xYZ)]?
        console.log 'caching tile: '+storeKey
        @_tileLoadQueue[Comm.StorageController.tileKey(xYZ)] = { promise: promise, deferred: false, storeFile: true }
      else
        console.log('storeTile - promise for '+Comm.StorageController.tileKey(xYZ)+' already stored in queue ...')
      return promise
    this._storeTileAsFile xYZ, null, data, deferredModeParams
  
  _getTileFile: (xYZ, noFileCB, deferredModeParams, firstCall = true) ->
    path = '/'+xYZ[2]+'/'+xYZ[0]+'/'+xYZ[1]
    @_dirReaders.entry.getFile(path, {}, (fileEntry) ->
        console.log('_getTileFile - found file: '+path)
        if deferredModeParams.fileStatusCB?
          deferredModeParams.fileStatusCB deferredModeParams, false
        if @_storedFilesAreBase64
          fileEntry.file (file) ->
              #@_dirReaders.entries[xYZ[2]].entries[xYZ[0].reader
              reader = new FileReader()
              reader.onabort = (e) ->
                  console.log('aborted '+path+": "+e)
              reader.onerror = (e) ->
                  console.log('failed '+path+": "+e)
              reader.onload = (e) ->
                  if this.result == ''
                    console.log('bad read on '+path)
                  deferredModeParams.deferred.resolve this.result
                  deferredModeParams.deferred = null
          reader.readAsText(file)
          #reader.readAsDataURL(file, APP.storage()._tileImageContentType)
        else
          deferredModeParams.deferred.resolve fileEntry.toURL(FileUtils.instance()._tileImageContentType)
          deferredModeParams.deferred = null
        delete FileUtils.instance()._tileLoadQueue[Comm.StorageController.tileKey(xYZ)]
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          if firstCall
            # check one more time if other thread stored file
            #console.log('_getTileFile - no such file / trying one more READ: '+path)
            return FileUtils.instance()._getTileFile xYZ, noFileCB, deferredModeParams, false
          else
            console.log('_getTileFile - no such file: '+path)
        else
          console.log('error: '+e+' for '+path)
        
        noFileCB e
      )

  # multithreaded access 
  _callOncePerTile: (xYZ, promise, checkStoreFile, storeFile, callback) ->
    storeKey = Comm.StorageController.tileKey(xYZ)
    stored = @_tileLoadQueue[storeKey]
    if stored?
      if checkStoreFile && stored.storeFile
        promise = callback(stored)
        stored.storeFile = false
      #console.log('_callOncePerTile - stored in queue: '+storeKey); 
      return stored.promise
    queueEntry = { promise: promise, deferred: false, storeFile: storeFile }
    # @see storeTile
    @_tileLoadQueue[storeKey] = queueEntry
    callback(queueEntry)

  loadAndPrefetchTile: (prefetchParams) ->
    sC = this
    this._callOncePerTile prefetchParams.xYZ, prefetchParams.promise, true, true, (queueEntry) ->
        console.log('FileUtils - loadAndPrefetchTile: '+Comm.StorageController.tileKey(prefetchParams.xYZ))
        noFileCB = (error) ->
            VoyageX.MapControl.loadAndPrefetch prefetchParams.xYZ, prefetchParams.view.subdomain, prefetchParams
        sC._getTileFile prefetchParams.xYZ, noFileCB, prefetchParams
        #prefetchParams.promise = prefetchParams.deferred.promise()
        #queueEntry.promise = prefetchParams.promise

  prefetchTile: (prefetchParams) ->
    sC = this
    this._callOncePerTile prefetchParams.xYZ, prefetchParams.promise, true, false, (queueEntry) ->
        console.log('FileUtils - prefetchTile: '+Comm.StorageController.tileKey(prefetchParams.xYZ))
        noFileCB = (error) ->
            MC.loadReadyImage prefetchParams.tileUrl, prefetchParams.xYZ, prefetchParams
        sC._getTileFile prefetchParams.xYZ, noFileCB, prefetchParams
        #prefetchParams.promise = prefetchParams.deferred.promise()
        #queueEntry.promise = prefetchParams.promise
        #queueEntry.storeFile = false
  
  getTile: (xYZ, deferredModeParams) ->
    sC = this
    this._callOncePerTile xYZ, deferredModeParams.promise, false, true, (queueEntry) ->
        console.log('FileUtils - getTile: '+Comm.StorageController.tileKey(xYZ))
        noFileCB = (error) ->
            # one mor check for asynchronous request - that's because of prefetch mit compete
            loadQueueEntry = FileUtils.instance()._tileLoadQueue[Comm.StorageController.tileKey(xYZ)]
            unless loadQueueEntry? && (!loadQueueEntry.storeFile)
              deferredModeParams.loadTileFromUrlCB deferredModeParams.view, deferredModeParams
              loadQueueEntry.deferred = true
            else
              console.log('TODO: _getTileFile - if this is logged then loadQueueEntry-check is necessary')
        sC._getTileFile xYZ, noFileCB, deferredModeParams
    deferredModeParams.promise

# ======================================================================
# poiNotes, userFotos
# ======================================================================

  _writeFile: (fileName, dirReader, data, deferredModeParams) ->
    dirReader.entry.getFile(fileName, {create: true}, (fileEntry) ->
          fileEntry.createWriter((fileWriter) ->
            fileWriter.onwriteend = (e) ->
                console.log('Write completed.')
                deferredModeParams.deferred.resolve fileEntry.toURL(deferredModeParams.fileMeta.content_type)
                deferredModeParams.deferred = null
                

# TODO
                # attachmentMeta = localStorage.getItem 'comm.poiNotes.attachmentMeta'
                # if attachmentMeta == null
                #   sC._attachmentMeta = { bytes: 0, count: 0 }
                # else
                #   sC._attachmentMeta = eval("(" + attachmentMeta + ")")
                # #sC._tileDB[storeKey] = data.properties.data
                # sC._attachmentMeta.count = sC._attachmentMeta.count+1
                # sC._attachmentMeta.bytes = sC._attachmentMeta.bytes+data.size
                # localStorage.setItem 'comm.poiNotes.attachmentMeta', JSON.stringify(sC._attachmentMeta)
                # #APP.view().showCacheStats(sC._tileMeta.numTiles, sC._tileMeta.tilesByteSize)



            fileWriter.onerror = (e) ->
                console.log('Write failed: ' + e.toString())
                #deferredModeParams.deferred.resolve deferredModeParams.tileUrl
                deferredModeParams.deferred.resolve Storage.Model.notInCacheImage(deferredModeParams.fileMeta)
                deferredModeParams.deferred = null
            console.log('saving file: '+dirReader.path+'/'+fileName)
            fileWriter.write(new Blob([data], {type: deferredModeParams.fileMeta.content_type}))
            # text-files
            #fileWriter.write(data.properties.data)
          , (e) ->
              console.log('_saveFile - '+e+' when trying to WRITE file '+dirReader.path+'/'+fileName)
          )
      , (e) ->
          console.log('_saveFile - '+e+' when trying to SAVE file '+dirReader.path+'/'+fileName)
      )

  _saveFile: (path, dirReader, data, deferredModeParams) ->
    fU = FileUtils.instance()
    pathString = dirReader.path+'/'+path[path.length-1]
    dirReader.entry.getFile(path[path.length-1], {}, (fileEntry) ->
        if deferredModeParams.update
          fU._writeFile path[path.length-1], dirReader, data, deferredModeParams
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR)
          fU._writeFile path[path.length-1], dirReader, data, deferredModeParams
        else
          console.log('_saveFile - '+e+' when trying to STORE file '+pathString)
          fU._storeAsFile path, dirReader, null, deferredModeParams
      )

  # path ... ['topDir','f1Dir',...,'file']
  _getDirectory: (path, curPathIndex, dirReader, data, deferredModeParams, firstCall = true) ->
    fU = FileUtils.instance()
    curPathDir = path[curPathIndex]
    pathString = (if dirReader.parent == null then '' else dirReader.path)+'/'+curPathDir
    dirReader.entry.getDirectory(curPathDir, {}, (fileEntry) ->
        #console.log('_getDirectory - found directory: '+pathString)
        unless dirReader.entries[curPathDir]?
          # file could exist after restarting app or other thread created id just before this thread getting here
          dirReader.entries[curPathDir] = { parent: dirReader, path: pathString, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
        fU._storeAsFile path, dirReader.entries[curPathDir], data, deferredModeParams, (curPathIndex+1)
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          console.log('creating directory: '+pathString)
          dirReader.entry.getDirectory(curPathDir, {create: true, exclusive: true}, (fileEntry) ->
              unless dirReader.entries[curPathDir]?
                # file could exist after restarting app or other thread created id just before this thread getting here
                dirReader.entries[curPathDir] = { parent: dirReader, path: pathString, entry: fileEntry, reader: fileEntry.createReader(), entries: {} }
              fU._storeAsFile path, dirReader.entries[curPathDir], data, deferredModeParams, (curPathIndex+1)
            , (e) ->
              if (e.code == FileError.NOT_FOUND_ERR) 
                console.log('_getDirectory - No such file: '+pathString)
              else
                # it's likely that directory has been created meanwhile by other request
                if firstCall
                  #console.log('_getDirectory - '+e+' when trying to CREATE directory / trying one more READ: '+pathString)
                  return fU._getDirectory path, curPathIndex, dirReader, data, deferredModeParams, false
                else
                  console.log('_getDirectory - '+e+' when trying to CREATE directory '+pathString)
              fU._storeAsFile path, dirReader, data, deferredModeParams, -1, curPathIndex
            )
        else
          console.log('_getDirectory - '+e+' when trying to READ directory '+pathString)
          fU._storeAsFile path, dirReader, data, deferredModeParams, -1, curPathIndex
      )

  _storeAsFile: (path, parentDirReader, data, deferredModeParams, nextPathIndex = 0, failedPathIndex = -1) ->
    if failedPathIndex != -1
      console.log('error: failedPathIndex = '+failedPathIndex+' for '+deferredModeParams)
    else if parentDirReader == null
      this._getDirectory path, nextPathIndex, @_dirReaders, data, deferredModeParams
    else if nextPathIndex < (path.length-1)
      this._getDirectory path, nextPathIndex, parentDirReader, data, deferredModeParams
    else# if data != null
      this._saveFile path, parentDirReader, data, deferredModeParams

  _getFile: (path, fileMeta, fileOwner, deferredModeParams) ->
    @_dirReaders.entry.getFile(path, {}, (fileEntry) ->
        console.log('_getFile - found file: '+path)
        if @_storedFilesAreBase64
          fileEntry.file (file) ->
              #@_dirReaders.entries[xYZ[2]].entries[xYZ[0].reader
              reader = new FileReader()
              reader.onabort = (e) ->
                  console.log('aborted '+path+": "+e)
              reader.onerror = (e) ->
                  console.log('failed '+path+": "+e)
              reader.onload = (e) ->
                  if this.result == ''
                    console.log('bad read on '+path)
                  deferredModeParams.deferred.resolve this.result
                  deferredModeParams.deferred = null
          reader.readAsText(file)
          #reader.readAsDataURL(file, APP.storage()._tileImageContentType)
        else
          # TODO - parametrize for return val - blob or url
          # tiles - url only  deferredModeParams.deferred.resolve fileEntry.toURL(fileMeta.content_type)
          # all uploads need blob - not url
          #deferredModeParams.deferred.resolve fileEntry.toURL(fileMeta.content_type), fileEntry.file
          fileEntry.file (file) ->
              deferredModeParams.deferred.resolve fileEntry.toURL(fileMeta.content_type), new Blob([file], { type: fileMeta.content_type })
              deferredModeParams.deferred = null
      , (e) ->
        if (e.code == FileError.NOT_FOUND_ERR) 
          console.log('_getFile - no such file: '+path)
        else
          console.log('_getFile - error: '+e+' for '+path)
        deferredModeParams.fileUrl fileOwner, deferredModeParams
      )
  
  getPoiNoteAttachmentFile: (poiNote, deferredModeParams) ->
    path = '/poiNotes/attachments/'+poiNote.id
    this._getFile path, poiNote.attachment, poiNote, deferredModeParams
  
  getUserPhotoFile: (user, deferredModeParams) ->
    path = '/users/photos/'+user.id
    this._getFile path, user.foto, user, deferredModeParams

  @instance: () ->
    @_SINGLETON
