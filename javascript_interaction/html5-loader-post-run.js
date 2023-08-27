  postRun: [
    function () {
      // This callback will be run once the game was started by clicking on the splash screen

      const readAndClearOutbox = function() {
        const filename = `${GDragonRubyWriteDir}/outbox`;
        const content = FS.readFile(filename, {
          encoding: 'utf8',
          // Need to use mode a+ to
          // - avoid an error for a non-existing file (as with r)
          // - avoid deleting the content before reading (as with w/w+)
          flags: FS_modeStringToFlags('a+')
        });

        if (content !== '') {
          FS.unlink(filename);
          // This must be synced back to the IndexedDB like this because FS is basically in memory
          // which is ok for reading but for writing you need to sync changes like this
          // First parameter determines sync direction (false = in memory -> IndexedDB)
          FS.syncfs(false, function(err) {
            if (err) {
              console.error(`Error while applying delete outbox: #{err}`);
            }
          });
          console.debug('removed outbox file');
        }

        return content;
      };

      const writeJSONToInbox = function(object) {
        const filename = `${GDragonRubyWriteDir}/inbox`;
        FS.writeFile(filename, JSON.stringify(object), {
            flags: FS_modeStringToFlags('w')
        });
      }

      function showUploadModal(listeners) {
        const modal = document.createElement('div');

        const hideModal = function() {
          document.body.removeChild(modal);
        }

        modal.style.position = 'fixed';
        modal.style.top = '50%';
        modal.style.left = '50%';
        modal.style.transform = 'translate(-50%, -50%)';
        modal.style.backgroundColor = 'white';
        modal.style.border = '1px solid black';
        modal.style.padding = '10px';
        modal.style.zIndex = '9999';

        var input = document.createElement('input');
        input.setAttribute('type', 'file');

        var okButton = document.createElement('button');
        okButton.textContent = 'OK';
        okButton.disabled = true

        input.addEventListener("change", function() {
          console.debug('File selected');
          okButton.disabled = false;
        });

        okButton.addEventListener('click', function() {
          const file = input.files[0];
          const reader = new FileReader();
          reader.readAsText(file);
          reader.onload = function() {
            console.debug('Modal: File uploaded');
            listeners.onFileUpload(reader.result);
            hideModal();
          };
        });

        var cancelButton = document.createElement("button");
        cancelButton.textContent = "Cancel";
        cancelButton.addEventListener("click", function() {
          console.debug('Modal: Upload canceled');
          hideModal();

          if (listeners.onCancel) {
            listeners.onCancel();
          }
        });

        modal.appendChild(input);
        modal.appendChild(okButton);
        modal.appendChild(cancelButton);

        document.body.appendChild(modal);
      }

      const downloadFile = function(content) {
        console.debug('Download file');
        const link = document.createElement("a");
        link.setAttribute("download", "file.txt");
        link.setAttribute("href", "data:text/plain," + encodeURIComponent(content));

        const fragment = document.createDocumentFragment();
        fragment.appendChild(link);
        link.click();
        fragment.removeChild(link);
      }

      const communicationInterval = 500;

      const communicateWithGame = function() {
        const scheduleNextExecution = function() {
          setTimeout(communicateWithGame, communicationInterval);
        };

        const outboxValue = readAndClearOutbox();
        console.debug(`Outbox value: '${outboxValue}'`);

        if (outboxValue === 'upload') {
          showUploadModal({
            onFileUpload: function (content) {
              writeJSONToInbox({
                type: 'file_upload',
                content: content
              });
              console.debug('Upload successful!');
              scheduleNextExecution();
            },
            onCancel: function() {
              writeJSONToInbox({
                type: 'upload_canceled'
              });
              console.debug('Upload canceled');
              scheduleNextExecution();
            }
          });
        } else if (outboxValue.startsWith('download,')) {
          const data = outboxValue.slice(9);
          downloadFile(data);
          scheduleNextExecution();
        } else {
          scheduleNextExecution();
        }
      }

      setTimeout(communicateWithGame, communicationInterval);
    })
  ],
