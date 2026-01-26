import { Controller } from "@hotwired/stimulus"

// File upload controller with preview and progress
export default class extends Controller {
  static targets = ["input", "preview", "progress", "error", "label"]
  static values = {
    maxSize: { type: Number, default: 10485760 }, // 10MB
    acceptedTypes: { type: Array, default: ["image/*", "application/pdf"] },
    direct: { type: Boolean, default: false },
    emptyLabel: { type: String, default: "No files selected" },
    selectedLabel: { type: String, default: "%{count} files selected" }
  }

  connect() {
    this.files = []
    this.updateLabel()
  }

  open() {
    if (this.hasInputTarget) {
      this.inputTarget.click()
    }
  }

  selectFiles(event) {
    const files = Array.from(event.target.files)
    
    // Validate files
    const validFiles = files.filter(file => this.validateFile(file))
    
    if (validFiles.length > 0) {
      this.files = validFiles
      this.displayPreviews()
      this.updateLabel()
      
      if (this.directValue) {
        this.uploadFiles()
      }
    } else {
      this.updateLabel()
    }
  }

  validateFile(file) {
    // Check file size
    if (file.size > this.maxSizeValue) {
      this.showError(`File ${file.name} exceeds maximum size of ${this.formatFileSize(this.maxSizeValue)}`)
      return false
    }

    // Check file type
    const fileType = file.type
    const isValid = this.acceptedTypesValue.some(type => {
      if (type.endsWith("/*")) {
        const baseType = type.split("/")[0]
        return fileType.startsWith(baseType)
      }
      return fileType === type
    })

    if (!isValid) {
      this.showError(`File ${file.name} type not accepted`)
      return false
    }

    this.clearError()
    return true
  }

  displayPreviews() {
    if (!this.hasPreviewTarget) return

    this.previewTarget.innerHTML = ""

    this.files.forEach((file, index) => {
      const previewElement = document.createElement("div")
      previewElement.className = "relative inline-block mr-4 mb-4"
      
      if (file.type.startsWith("image/")) {
        const reader = new FileReader()
        reader.onload = (e) => {
          previewElement.innerHTML = `
            <img src="${e.target.result}" class="w-24 h-24 object-cover rounded-lg border border-stroke" />
            <button type="button" 
                    class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center hover:bg-red-600"
                    data-action="click->file-upload#removeFile"
                    data-index="${index}">
              <span class="material-icons text-xs">close</span>
            </button>
          `
        }
        reader.readAsDataURL(file)
      } else {
        previewElement.innerHTML = `
          <div class="w-24 h-24 flex flex-col items-center justify-center bg-whiter dark:bg-boxdark rounded-lg border border-stroke">
            <span class="material-icons text-2xl text-bodydark1">description</span>
            <span class="text-xs text-bodydark1 mt-1">${file.name.split(".").pop().toUpperCase()}</span>
          </div>
          <button type="button"
                  class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center hover:bg-red-600"
                  data-action="click->file-upload#removeFile"
                  data-index="${index}">
            <span class="material-icons text-xs">close</span>
          </button>
        `
      }

      this.previewTarget.appendChild(previewElement)
    })
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.files.splice(index, 1)
    this.displayPreviews()
    this.updateLabel()

    // Clear input if no files left
    if (this.files.length === 0) {
      this.inputTarget.value = ""
    }
  }

  updateLabel() {
    if (!this.hasLabelTarget) return

    if (this.files.length === 0) {
      this.labelTarget.textContent = this.emptyLabelValue
      return
    }

    if (this.files.length === 1) {
      this.labelTarget.textContent = this.files[0].name
      return
    }

    this.labelTarget.textContent = this.selectedLabelValue.replace("%{count}", this.files.length)
  }

  async uploadFiles() {
    if (this.files.length === 0) return

    const formData = new FormData()
    this.files.forEach(file => {
      formData.append("files[]", file)
    })

    try {
      if (this.hasProgressTarget) {
        this.showProgress()
      }

      const response = await fetch(this.element.dataset.uploadUrl || "/uploads", {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      if (!response.ok) throw new Error("Upload failed")

      const data = await response.json()
      
      this.element.dispatchEvent(new CustomEvent("file-upload:complete", {
        detail: { files: data },
        bubbles: true
      }))

      this.clearFiles()
    } catch (error) {
      this.showError("Upload failed. Please try again.")
      console.error("Upload error:", error)
    } finally {
      if (this.hasProgressTarget) {
        this.hideProgress()
      }
    }
  }

  clearFiles() {
    this.files = []
    this.inputTarget.value = ""
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = ""
    }
    this.updateLabel()
  }

  showProgress() {
    this.progressTarget.classList.remove("hidden")
  }

  hideProgress() {
    this.progressTarget.classList.add("hidden")
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + " " + sizes[i]
  }
}
