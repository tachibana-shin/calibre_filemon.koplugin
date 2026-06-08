local WidgetContainer = require("ui/widget/container/widgetcontainer")
local lfs = require("libs/libkoreader-lfs")
local rapidjson = require("rapidjson")
local logger = require("logger")
local ffiUtil = require("ffi/util")

local CalibreFileMon = WidgetContainer:extend{
    name = "calibre_filemon",
    is_doc_only = false,
}

local fm_wrapped = false

function CalibreFileMon:getInboxDir()
    return G_reader_settings:readSetting("inbox_dir")
end

function CalibreFileMon:getCalibreRelativePath(fullpath)
    local inbox_dir = self:getInboxDir()
    if not inbox_dir then return nil, nil end
    local prefix = inbox_dir .. "/"
    if fullpath:sub(1, #prefix) == prefix then
        return inbox_dir, fullpath:sub(#prefix + 1)
    end
    return nil, nil
end

function CalibreFileMon:loadMetadata(inbox_dir)
    local meta_file = inbox_dir .. "/metadata.calibre"
    local attr = lfs.attributes(meta_file)
    if not attr or attr.mode ~= "file" or attr.size == 0 then
        return nil
    end
    -- Use load_calibre for compatibility with Calibre's JSON format
    local books, err = rapidjson.load_calibre(meta_file)
    if not books then
        logger.warn("CalibreFileMon: failed to load", meta_file, err)
        return nil
    end
    return books
end

function CalibreFileMon:saveMetadata(inbox_dir, books)
    local meta_file = inbox_dir .. "/metadata.calibre"
    rapidjson.dump(books, meta_file, { pretty = true })
end

function CalibreFileMon:onFileMoved(old_fullpath, new_fullpath)
    local inbox_dir, old_rel = self:getCalibreRelativePath(old_fullpath)
    if not inbox_dir then return end
    local _, new_rel = self:getCalibreRelativePath(new_fullpath)
    if not new_rel or old_rel == new_rel then return end

    local books = self:loadMetadata(inbox_dir)
    if not books then return end

    for i, book in ipairs(books) do
        if book.lpath == old_rel then
            book.lpath = new_rel
            self:saveMetadata(inbox_dir, books)
            logger.info("CalibreFileMon: updated lpath", old_rel, "->", new_rel)
            return
        end
    end
end

function CalibreFileMon:onFileDeleted(fullpath)
    local inbox_dir, rel = self:getCalibreRelativePath(fullpath)
    if not inbox_dir then return end

    local books = self:loadMetadata(inbox_dir)
    if not books then return end

    local found = false
    for i = #books, 1, -1 do
        if books[i].lpath == rel then
            table.remove(books, i)
            found = true
        end
    end

    if found then
        self:saveMetadata(inbox_dir, books)
        logger.info("CalibreFileMon: removed entry for", rel)
    end
end

function CalibreFileMon:wrapFileManager()
    if fm_wrapped then return end
    fm_wrapped = true

    local FileManager = require("apps/filemanager/filemanager")
    local plugin = self

    local orig_moveFile = FileManager.moveFile
    FileManager.moveFile = function(self, from, to)
        local ok = orig_moveFile(self, from, to)
        if not ok then return false end

        local dest_file
        local to_attr = lfs.attributes(to)
        if to_attr and to_attr.mode == "directory" then
            dest_file = ffiUtil.joinPath(to, ffiUtil.basename(from))
        else
            dest_file = to
        end

        if lfs.attributes(dest_file, "mode") == "file" then
            plugin:onFileMoved(from, dest_file)
        end

        return true
    end

    local orig_delete = FileManager.deleteFile
    FileManager.deleteFile = function(self, file, is_file)
        local ok = orig_delete(self, file, is_file)
        if ok then
            plugin:onFileDeleted(file)
        end
        return ok
    end

    local orig_deleteSelected = FileManager.deleteSelectedFiles
    FileManager.deleteSelectedFiles = function(self)
        local files = {}
        for orig_file in pairs(self.selected_files) do
            table.insert(files, orig_file)
        end
        orig_deleteSelected(self)
        for _, file in ipairs(files) do
            if not lfs.attributes(file, "mode") then
                plugin:onFileDeleted(file)
            end
        end
    end

    logger.info("CalibreFileMon: FileManager wrapped")
end

function CalibreFileMon:init()
    if self._initialized then return end
    self._initialized = true
    self:wrapFileManager()
end

return CalibreFileMon
