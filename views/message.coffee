$ ->
  window.requestFileSystem = window.requestFileSystem || window.webkitRequestFileSystem

  sendMessage = (message) ->
    $.ajax
      url: "/message"
      method: "POST"
      data: message

  transferFile = (file) ->
    formData = new FormData
    formData.append("file", file)

    xhr = new XMLHttpRequest()
    xhr.open("POST", "/file")
    xhr.send(formData)

  buffers = {}
  bufferFile = (filename, data) ->
    console.log("Buffering #{filename}")
    buffers[filename] = [] unless filename of buffers
    buffers[filename].push(data)

  endFile = (filename) ->
    console.log("#{filename} finished")

    buffer = buffers[filename]
    delete buffers[filename]

    window.requestFileSystem TEMPORARY, 1024 * 1024 * 1024, (fs) ->
      fs.root.getFile filename, { create: true }, (entry) ->
        entry.createWriter (writer) ->
          writer.onwriteend = (e) -> fileWritten(filename, entry)
          writer.onerror = (e) -> console.log("Error: #{e.toString()}")

          blob = new Blob(buffer, type: "application/octet-binary")
          writer.write(blob)
        , ->
          alert("Unable to create writer")
      , ->
        alert("Unable to get file")
    , ->
      alert("Unable to receive #{filename}. Did you deny us access?")

  fileWritten = (filename, entry) ->
    fileLink = $("<a>").
      prop("href", entry.toURL()).
      text(filename)

    $("<li>").
      append("#{new Date().toString()}: ").
      append(fileLink).
      appendTo("#files")

  messageStream = new EventSource("/stream")
  messageStream.addEventListener "FILEDATA", (e) ->
    message = JSON.parse(e.data)
    bufferFile(message.filename, atob(message.data))
  messageStream.addEventListener "FILEEND", (e) ->
    message = JSON.parse(e.data)
    endFile(message.filename)

  document.body.ondragover = -> false
  document.body.ondragend  = -> false
  document.body.ondrop = (e) ->
    e.preventDefault()
    if e.dataTransfer.files.length > 0
      transferFile(e.dataTransfer.files[0])
