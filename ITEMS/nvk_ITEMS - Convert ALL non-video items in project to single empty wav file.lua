-- @noindex
-- USER CONFIG --
FileLength = 180 -- length of empty file in seconds
FileName = "Silence"
-- SETUP --
function GetPath(a, b)
    if not b then
        b = ".dat"
    end
    local c = scrPath .. "Data" .. sep .. a .. b;
    return c
end
OS = reaper.GetOS()
sep = OS:match "Win" and "\\" or "/"
scrPath, scrName = ({reaper.get_action_context()})[2]:match "(.-)([^/\\]+).lua$"
loadfile(GetPath "functions")()
if not functionsLoaded then
    return
end
-- SCRIPT --

------------------------------------------------------------------------------------
--[[
	Library for simple audio reading, writing and analysing.
	
	Copyright © 2014, Christoph "Youka" Spanknebel
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
wav = {
    --[[
		Reads or writes audio file in WAVE format with PCM integer samples.
		
		Function 'create_context' requires 2 arguments: a filename and a mode, which can be "r" (read) or "w" (write).
		A call returns one table with methods depending on the used mode.
		On reading, following methods are callable:
		- get_filename()
		- get_mode()
		- get_file_size()
		- get_channels_number()
		- get_sample_rate()
		- get_byte_rate()
		- get_block_align()
		- get_bits_per_sample()
		- get_samples_per_channel()
		- get_sample_from_ms(ms)
		- get_ms_from_sample(sample)
		- get_min_max_amplitude()
		- get_position()
		- set_position(pos)
		- get_samples_interlaced(n)
		- get_samples(n)
		On writing, following methods are callable:
		- get_filename()
		- get_mode()
		- init(channels_number, sample_rate, bits_per_sample)
		- write_samples_interlaced(samples)
		- finish()
		
		(WAVE format: https://ccrma.stanford.edu/courses/422/projects/WaveFormat/)
	]]
    create_context = function(filename, mode)
        -- Check function parameters
        if type(filename) ~= "string" or not (mode == "r" or mode == "w") then
            error("invalid function parameters, expected filename and mode \"r\" or \"w\"", 2)
        end
        -- Audio file handle
        local file = io.open(filename, mode == "r" and "rb" or "wb")
        if not file then
            error(string.format("couldn't open file %q", filename), 2)
        end
        -- Byte-string(unsigend integer,little endian)<->Lua-number converters
        local function bton(s)
            local bytes = {s:byte(1, #s)}
            local n, bytes_n = 0, #bytes
            for i = 0, bytes_n - 1 do
                n = n + bytes[1 + i] * 2 ^ (i * 8)
            end
            return n
        end
        local unpack = table.unpack or unpack -- Lua 5.1 or 5.2 table unpacker
        local function ntob(n, len)
            local n, bytes = math.max(math.floor(n), 0), {}
            for i = 1, len do
                bytes[i] = n % 256
                n = math.floor(n / 256)
            end
            return string.char(unpack(bytes))
        end
        -- Check for integer
        local function isint(n)
            return type(n) == "number" and n == math.floor(n)
        end
        -- Initialize read process
        if mode == "r" then
            -- Audio meta informations
            local file_size, channels_number, sample_rate, byte_rate, block_align, bits_per_sample, samples_per_channel
            -- Audio samples file area
            local data_begin, data_end
            -- Read file type
            if file:read(4) ~= "RIFF" then
                error("not a RIFF file", 2)
            end
            file_size = file:read(4)
            if not file_size then
                error("file header incomplete (file size)")
            end
            file_size = bton(file_size) + 8
            if file:read(4) ~= "WAVE" then
                error("not a WAVE file", 2)
            end
            -- Read file chunks
            local chunk_id, chunk_size
            while true do
                -- Read chunk header
                chunk_id, chunk_size = file:read(4), file:read(4)
                if not chunk_size then
                    break
                end
                chunk_size = bton(chunk_size)
                -- Identify chunk type
                if chunk_id == "fmt " then
                    -- Read format informations
                    local bytes = file:read(2)
                    if not bytes or bton(bytes) ~= 1 then
                        error("data must be in PCM format", 2)
                    end
                    bytes = file:read(2)
                    if not bytes then
                        error("channels number not found", 2)
                    end
                    channels_number = bton(bytes)
                    bytes = file:read(4)
                    if not bytes then
                        error("sample rate not found", 2)
                    end
                    sample_rate = bton(bytes)
                    bytes = file:read(4)
                    if not bytes then
                        error("byte rate not found", 2)
                    end
                    byte_rate = bton(bytes)
                    bytes = file:read(2)
                    if not bytes then
                        error("block align not found", 2)
                    end
                    block_align = bton(bytes)
                    bytes = file:read(2)
                    if not bytes then
                        error("bits per sample not found")
                    end
                    bits_per_sample = bton(bytes)
                    if bits_per_sample ~= 8 and bits_per_sample ~= 16 and bits_per_sample ~= 24 and bits_per_sample ~=
                        32 then
                        error("bits per sample must be 8, 16, 24 or 32", 2)
                    end
                    file:seek("cur", chunk_size - 16)
                elseif chunk_id == "data" then
                    -- Read samples
                    if not block_align then
                        error("format informations must be defined before sample data", 2)
                    end
                    samples_per_channel = chunk_size / block_align
                    data_begin = file:seek()
                    data_end = data_begin + chunk_size
                    break -- Stop here for later reading
                else
                    -- Skip chunk
                    file:seek("cur", chunk_size)
                end
            end
            -- Enough informations available?
            if not bits_per_sample then
                error("no format informations found", 2)
            end
            -- Return audio handler
            local obj
            obj = {
                get_filename = function()
                    return filename
                end,
                get_mode = function()
                    return mode
                end,
                get_file_size = function()
                    return file_size
                end,
                get_channels_number = function()
                    return channels_number
                end,
                get_sample_rate = function()
                    return sample_rate
                end,
                get_byte_rate = function()
                    return byte_rate
                end,
                get_block_align = function()
                    return block_align
                end,
                get_bits_per_sample = function()
                    return bits_per_sample
                end,
                get_samples_per_channel = function()
                    return samples_per_channel
                end,
                get_sample_from_ms = function(ms)
                    if not isint(ms) or ms < 0 then
                        error("positive integer expected", 2)
                    end
                    return ms * 0.001 * sample_rate
                end,
                get_ms_from_sample = function(sample)
                    if not isint(sample) or sample < 0 then
                        error("positive integer expected", 2)
                    end
                    return sample / sample_rate * 1000
                end,
                get_min_max_amplitude = function()
                    local half_level = 2 ^ bits_per_sample / 2
                    return -half_level, half_level - 1
                end,
                get_position = function()
                    if not data_begin then
                        error("no samples available", 2)
                    end
                    return (file:seek() - data_begin) / block_align
                end,
                set_position = function(pos)
                    if not isint(pos) or pos < 0 then
                        error("positive integer expected", 2)
                    elseif not data_begin then
                        error("no samples available", 2)
                    elseif data_begin + pos * block_align > data_end then
                        error("tried to set position behind data end", 2)
                    end
                    file:seek("set", data_begin + pos * block_align)
                end,
                get_samples_interlaced = function(n)
                    if not isint(n) or n <= 0 then
                        error("positive integer greater zero expected", 2)
                    elseif not data_begin then
                        error("no samples available", 2)
                    elseif file:seek() + n * block_align > data_end then
                        error("tried to read over data end", 2)
                    end
                    local bytes, sample, output = file:read(n * block_align), nil, {
                        n = 0
                    }
                    local bytes_n = #bytes
                    if bits_per_sample == 8 then
                        for i = 1, bytes_n, 1 do
                            sample = bton(bytes:sub(i, i))
                            output.n = output.n + 1
                            output[output.n] = sample > 127 and sample - 256 or sample
                        end
                    elseif bits_per_sample == 16 then
                        for i = 1, bytes_n, 2 do
                            sample = bton(bytes:sub(i, i + 1))
                            output.n = output.n + 1
                            output[output.n] = sample > 32767 and sample - 65536 or sample
                        end
                    elseif bits_per_sample == 24 then
                        for i = 1, bytes_n, 3 do
                            sample = bton(bytes:sub(i, i + 2))
                            output.n = output.n + 1
                            output[output.n] = sample > 8388607 and sample - 16777216 or sample
                        end
                    else -- if bits_per_sample == 32 then
                        for i = 1, bytes_n, 4 do
                            sample = bton(bytes:sub(i, i + 3))
                            output.n = output.n + 1
                            output[output.n] = sample > 2147483647 and sample - 4294967296 or sample
                        end
                    end
                    return output
                end,
                get_samples = function(n)
                    local success, samples = pcall(obj.get_samples_interlaced, n)
                    if not success then
                        error(samples, 2)
                    end
                    local output, channel_samples = {
                        n = channels_number
                    }
                    for c = 1, output.n do
                        channel_samples = {
                            n = samples.n / channels_number
                        }
                        for s = 1, channel_samples.n do
                            channel_samples[s] = samples[c + (s - 1) * channels_number]
                        end
                        output[c] = channel_samples
                    end
                    return output
                end
            }
            return obj
            -- Initialize write process
        else
            -- Audio meta informations
            local channels_number_private, bytes_per_sample
            -- Return audio handler
            return {
                get_filename = function()
                    return filename
                end,
                get_mode = function()
                    return mode
                end,
                init = function(channels_number, sample_rate, bits_per_sample)
                    -- Check function parameters
                    if not isint(channels_number) or channels_number < 1 or not isint(sample_rate) or sample_rate < 2 or
                        not (bits_per_sample == 8 or bits_per_sample == 16 or bits_per_sample == 24 or bits_per_sample ==
                            32) then
                        error("valid channels number, sample rate and bits per sample expected", 2)
                        -- Already finished?
                    elseif not file then
                        error("already finished", 2)
                        -- Already initialized?
                    elseif file:seek() > 0 then
                        error("already initialized", 2)
                    end
                    -- Write file type
                    file:write("RIFF????WAVE") -- file size to insert later
                    -- Write format chunk
                    file:write("fmt ", ntob(16, 4), ntob(1, 2), ntob(channels_number, 2), ntob(sample_rate, 4),
                        ntob(sample_rate * channels_number * (bits_per_sample / 8), 4),
                        ntob(channels_number * (bits_per_sample / 8), 2), ntob(bits_per_sample, 2))
                    -- Write data chunk (so far)
                    file:write("data????") -- data size to insert later
                    -- Set format memory
                    channels_number_private, bytes_per_sample = channels_number, bits_per_sample / 8
                end,
                write_samples_interlaced = function(samples)
                    -- Check function parameters
                    if type(samples) ~= "table" then
                        error("samples table expected", 2)
                    end
                    local samples_n = #samples
                    if samples_n == 0 or samples_n % channels_number_private ~= 0 then
                        error("valid number of samples expected (multiple of channels)", 2)
                        -- Already finished?
                    elseif not file then
                        error("already finished", 2)
                        -- Already initialized?
                    elseif file:seek() == 0 then
                        error("initialize before writing samples", 2)
                    end
                    -- All samples are numbers?
                    for i = 1, samples_n do
                        if type(samples[i]) ~= "number" then
                            error("samples have to be numbers", 2)
                        end
                    end
                    -- Write samples to file
                    local sample
                    if bytes_per_sample == 1 then
                        for i = 1, samples_n do
                            sample = samples[i]
                            file:write(ntob(sample < 0 and sample + 256 or sample, 1))
                        end
                    elseif bytes_per_sample == 2 then
                        for i = 1, samples_n do
                            sample = samples[i]
                            file:write(ntob(sample < 0 and sample + 65536 or sample, 2))
                        end
                    elseif bytes_per_sample == 3 then
                        for i = 1, samples_n do
                            sample = samples[i]
                            file:write(ntob(sample < 0 and sample + 16777216 or sample, 3))
                        end
                    else -- if bytes_per_sample == 4 then
                        for i = 1, samples_n do
                            sample = samples[i]
                            file:write(ntob(sample < 0 and sample + 4294967296 or sample, 4))
                        end
                    end
                end,
                finish = function()
                    -- Already finished?
                    if not file then
                        error("already finished", 2)
                        -- Already initialized?
                    elseif file:seek() == 0 then
                        error("initialize before finishing", 2)
                    end
                    -- Get file size
                    local file_size = file:seek()
                    -- Save file size
                    file:seek("set", 4)
                    file:write(ntob(file_size - 8, 4))
                    -- Save data size
                    file:seek("set", 40)
                    file:write(ntob(file_size - 44, 4))
                    -- Finalize file for secure reading
                    file:close()
                    file = nil
                end
            }
        end
    end,
    --[[
		Analyses frequencies of audio samples.
		
		Function 'create_frequency_analyzer' requires 2 arguments: a table with audio samples and the relating sample rate.
		A call returns one table with following methods:
		- get_frequencies()
		- get_frequency_weight(freq)
		- get_frequency_range_weight(freq_min, freq_max)
		
		(FFT: http://www.relisoft.com/science/physics/fft.html)
	]]
    create_frequency_analyzer = function(samples, sample_rate)
        -- Check function parameters
        if type(samples) ~= "table" or type(sample_rate) ~= "number" or sample_rate ~= math.floor(sample_rate) or
            sample_rate < 2 then
            error("samples table and sample rate expected", 2)
        end
        local samples_n = #samples
        if samples_n ~= math.ceil_pow2(samples_n) then
            error("table size has to be a power of two", 2)
        end
        for _, sample in ipairs(samples) do
            if type(sample) ~= "number" then
                error("table has only to contain numbers", 2)
            elseif sample > 1 or sample < -1 then
                error("numbers should be normalized / limited to -1 until 1", 2)
            end
        end
        -- Complex numbers
        local complex_t
        do
            local complex = {}
            local function tocomplex(a, b)
                if getmetatable(b) ~= complex then
                    return a, {
                        r = b,
                        i = 0
                    }
                elseif getmetatable(a) ~= complex then
                    return {
                        r = a,
                        i = 0
                    }, b
                else
                    return a, b
                end
            end
            complex.__add = function(a, b)
                local c1, c2 = tocomplex(a, b)
                return setmetatable({
                    r = c1.r + c2.r,
                    i = c1.i + c2.i
                }, complex)
            end
            complex.__sub = function(a, b)
                local c1, c2 = tocomplex(a, b)
                return setmetatable({
                    r = c1.r - c2.r,
                    i = c1.i - c2.i
                }, complex)
            end
            complex.__mul = function(a, b)
                local c1, c2 = tocomplex(a, b)
                return setmetatable({
                    r = c1.r * c2.r - c1.i * c2.i,
                    i = c1.r * c2.i + c1.i * c2.r
                }, complex)
            end
            complex.__index = complex
            complex_t = function(r, i)
                return setmetatable({
                    r = r,
                    i = i
                }, complex)
            end
        end
        local function polar(theta)
            return complex_t(math.cos(theta), math.sin(theta))
        end
        local function magnitude(c)
            return math.sqrt(c.r ^ 2 + c.i ^ 2)
        end
        -- Fast Fourier Transform
        local function fft(x)
            -- Check recursion break
            local N = x.n
            if N > 1 then
                -- Divide
                local even, odd = {
                    n = 0
                }, {
                    n = 0
                }
                for i = 1, N, 2 do
                    even.n = even.n + 1
                    even[even.n] = x[i]
                end
                for i = 2, N, 2 do
                    odd.n = odd.n + 1
                    odd[odd.n] = x[i]
                end
                -- Conquer
                fft(even)
                fft(odd)
                -- Combine
                local t
                for k = 1, N / 2 do
                    t = polar(-2 * math.pi * (k - 1) / N) * odd[k]
                    x[k] = even[k] + t
                    x[k + N / 2] = even[k] - t
                end
            end
        end
        -- Numbers to complex numbers
        local data = {
            n = samples_n
        }
        for i = 1, data.n do
            data[i] = complex_t(samples[i], 0)
        end
        -- Process FFT
        fft(data)
        -- Complex numbers to numbers
        for i = 1, data.n do
            data[i] = magnitude(data[i])
        end
        -- Calculate ordered frequencies
        local frequencies, frequency_sum, sample_rate_half = {
            n = data.n / 2
        }, 0, sample_rate / 2
        for i = 1, frequencies.n do
            frequency_sum = frequency_sum + data[i]
        end
        if frequency_sum > 0 then
            for i = 1, frequencies.n do
                frequencies[i] = {
                    freq = (i - 1) / (frequencies.n - 1) * sample_rate_half,
                    weight = data[i] / frequency_sum
                }
            end
        else
            frequencies[1] = {
                freq = 0,
                weight = 1
            }
            for i = 2, frequencies.n do
                frequencies[i] = {
                    freq = (i - 1) / (frequencies.n - 1) * sample_rate_half,
                    weight = 0
                }
            end
        end
        -- Return frequencies getter
        return {
            get_frequencies = function()
                local out = {
                    n = frequencies.n
                }
                for i = 1, frequencies.n do
                    out[i] = {
                        freq = frequencies[i].freq,
                        weight = frequencies[i].weight
                    }
                end
                return out
            end,
            get_frequency_weight = function(freq)
                if type(freq) ~= "number" or freq < 0 or freq > sample_rate_half then
                    error("valid frequency expected", 2)
                end
                for i, frequency in ipairs(frequencies) do
                    if frequency.freq == freq then
                        return frequency.weight
                    elseif frequency.freq > freq then
                        local frequency_last = frequencies[i - 1]
                        return (freq - frequency_last.freq) / (frequency.freq - frequency_last.freq) *
                                   (frequency.weight - frequency_last.weight) + frequency_last.weight
                    end
                end
            end,
            get_frequency_range_weight = function(freq_min, freq_max)
                if type(freq_min) ~= "number" or freq_min < 0 or freq_min > sample_rate_half or type(freq_max) ~=
                    "number" or freq_max < 0 or freq_max > sample_rate_half or freq_min > freq_max then
                    error("valid frequencies expected", 2)
                end
                local weight_sum = 0
                for _, frequency in ipairs(frequencies) do
                    if frequency.freq >= freq_min and frequency.freq <= freq_max then
                        weight_sum = weight_sum + frequency.weight
                    end
                end
                return weight_sum
            end
        }
    end
}

--[[
	Rounds up number to power of 2.
]]
function math.ceil_pow2(x)
    if type(x) ~= "number" then
        error("number expected", 2)
    end
    local p = 2
    while p < x do
        p = p * 2
    end
    return p
end

--[[
	Rounds down number to power of 2.
]]
function math.floor_pow2(x)
    if type(x) ~= "number" then
        error("number expected", 2)
    end
    local y = math.ceil_pow2(x)
    return x == y and x or y / 2
end

--[[
	Rounds number nearest to power of 2.
]]
function math.round_pow2(x)
    if type(x) ~= "number" then
        error("number expected", 2)
    end
    local min, max = math.floor_pow2(x), math.ceil_pow2(x)
    return (x - min) / (max - min) < 0.5 and min or max
end

--[[
	Converts samples into an ASS (Advanced Substation Alpha) subtitle shape code.
]]
function audio_to_ass(samples, wave_width, wave_height_scale, wave_thickness)
    -- Check function parameters
    if type(samples) ~= "table" or not samples[1] or type(wave_width) ~= "number" or wave_width <= 0 or
        type(wave_height_scale) ~= "number" or type(wave_thickness) ~= "number" or wave_thickness <= 0 then
        error("samples table, positive wave width, height scale and thickness expected", 2)
    end
    for _, sample in ipairs(samples) do
        if type(sample) ~= "number" then
            error("table has only to contain numbers", 2)
        end
    end
    -- Better fitting forms of known variables for most use
    local thick2, samples_n = wave_thickness / 2, #samples
    -- Build shape
    local shape = string.format("m 0 %d l", samples[1] * wave_height_scale - thick2)
    for i = 2, samples_n do
        shape = string.format("%s %d %d", shape, (i - 1) / (samples_n - 1) * wave_width,
            samples[i] * wave_height_scale - thick2)
    end
    for i = samples_n, 1, -1 do
        shape = string.format("%s %d %d", shape, (i - 1) / (samples_n - 1) * wave_width,
            samples[i] * wave_height_scale + thick2)
    end
    return shape
end

----------------------------------------------------------------------------------
local OS = reaper.GetOS()
local sep = "/"
if OS:match("Win") then
    sep = "\\"
end

function RecordFileName(name)
    local path = reaper.GetProjectPath(0) -- gets record path (bad name)
    local proj = reaper.GetProjectName(0)
    local ext = ".wav"
    if not name then
        name = proj and proj:match("(.*)%.") or "Untitled"
    end

    local file = path .. sep .. name
    local i = 1
    local num
    if reaper.file_exists(file .. ext) then
        -- file = file .. "_"
        -- while true do
        --     num = string.format("%03d", tostring(i))
        --     if not reaper.file_exists(file .. num .. ext) then
        --         break
        --     end
        --     i = i + 1
        -- end
        -- return file .. num .. ext
        return true, file .. ext
    else
        return false, file .. ext
    end
end

function CreateWavFile(name, length)
    name = tostring(FileName) or name
    length = tonumber(FileLength) or length
    local file_exists, file = RecordFileName(name)
    if not file_exists then
        wavFile = wav.create_context(file, "w")
        wavFile.init(1, 48000, 16)
        local t = {}
        for i = 1, length * 48000 do
            t[i] = 0
        end
        wavFile.write_samples_interlaced(t)
        wavFile.finish()
    end
    return file_exists, file
end

function ReplaceItemSource(item)
    local take = reaper.GetActiveTake(item)
    if take then
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local name = reaper.GetTakeName(take)
        local file_exists, file = CreateWavFile(name, itemLength)
        reaper.BR_SetTakeSourceFromFile(take, file, false)
        return file_exists, file
    end
end

function Main()
    local items = {}
    local existingFiles = {}
    local newFiles = {}
    for i = 0, reaper.CountMediaItems(0) - 1 do
        local item = reaper.GetMediaItem(0, i)
        table.insert(items, item)
    end
    reaper.SelectAllMediaItems(0, false)
    for i, item in ipairs(items) do
        local take = reaper.GetActiveTake(item)
        if not IsVideoItem(item) then
            reaper.SetMediaItemSelected(item, true)
        end
    end
    reaper.Main_OnCommand(40131, 0) -- crop to active take in items
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local file_exists, file = ReplaceItemSource(item)
        if file_exists then
            table.insert(existingFiles, file)
        else
            table.insert(newFiles, file)
        end
    end
    reaper.ShowMessageBox("Success", "All non-video files converted to silent wave file", 0)
    --msg("Files created:")
    --msg(newFiles)
    --msg("Existing files:")
    --msg(existingFiles)
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scrName, -1)
