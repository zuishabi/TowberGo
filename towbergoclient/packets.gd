#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && (varint[8] & 0x80 != 0):
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var result : PackedByteArray = PackedByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func skip_unknown_field(bytes : PackedByteArray, offset : int, type : int) -> int:
		if type == PB_TYPE.VARINT:
			return offset + isolate_varint(bytes, offset).size()
		if type == PB_TYPE.FIX64:
			return offset + 8
		if type == PB_TYPE.LENGTHDEL:
			var length_bytes : PackedByteArray = isolate_varint(bytes, offset)
			var length : int = unpack_varint(length_bytes)
			return offset + length_bytes.size() + length
		if type == PB_TYPE.FIX32:
			return offset + 4
		return PB_ERR.UNDEFINED_STATE

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
				else:
					var res : int = skip_unknown_field(bytes, offset, tt.type)
					if res > 0:
						offset = res
						if offset == limit:
							return offset
						elif offset > limit:
							return PB_ERR.PACKAGE_SIZE_MISMATCH
					elif res < 0:
						return res
					else:
						break							
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class LoginRequestMessage:
	func _init():
		var service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__password = PBField.new("password", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __password
		data[__password.tag] = service
		
	var data = {}
	
	var __username: PBField
	func has_username() -> bool:
		if __username.value != null:
			return true
		return false
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __password: PBField
	func has_password() -> bool:
		if __password.value != null:
			return true
		return false
	func get_password() -> String:
		return __password.value
	func clear_password() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__password.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_password(value : String) -> void:
		__password.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RegisterRequestMessage:
	func _init():
		var service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__password = PBField.new("password", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __password
		data[__password.tag] = service
		
	var data = {}
	
	var __username: PBField
	func has_username() -> bool:
		if __username.value != null:
			return true
		return false
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __password: PBField
	func has_password() -> bool:
		if __password.value != null:
			return true
		return false
	func get_password() -> String:
		return __password.value
	func clear_password() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__password.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_password(value : String) -> void:
		__password.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class OKResponseMessage:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DenyResponseMessage:
	func _init():
		var service
		
		__reason = PBField.new("reason", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __reason
		data[__reason.tag] = service
		
	var data = {}
	
	var __reason: PBField
	func has_reason() -> bool:
		if __reason.value != null:
			return true
		return false
	func get_reason() -> String:
		return __reason.value
	func clear_reason() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__reason.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_reason(value : String) -> void:
		__reason.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LoginSuccessMessage:
	func _init():
		var service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__uid = PBField.new("uid", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __uid
		data[__uid.tag] = service
		
	var data = {}
	
	var __username: PBField
	func has_username() -> bool:
		if __username.value != null:
			return true
		return false
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __uid: PBField
	func has_uid() -> bool:
		if __uid.value != null:
			return true
		return false
	func get_uid() -> int:
		return __uid.value
	func clear_uid() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_uid(value : int) -> void:
		__uid.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerEnterAreaRequestMessage:
	func _init():
		var service
		
		__area_name = PBField.new("area_name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __area_name
		data[__area_name.tag] = service
		
		__entrance_id = PBField.new("entrance_id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __entrance_id
		data[__entrance_id.tag] = service
		
	var data = {}
	
	var __area_name: PBField
	func has_area_name() -> bool:
		if __area_name.value != null:
			return true
		return false
	func get_area_name() -> String:
		return __area_name.value
	func clear_area_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__area_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_area_name(value : String) -> void:
		__area_name.value = value
	
	var __entrance_id: PBField
	func has_entrance_id() -> bool:
		if __entrance_id.value != null:
			return true
		return false
	func get_entrance_id() -> int:
		return __entrance_id.value
	func clear_entrance_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__entrance_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_entrance_id(value : int) -> void:
		__entrance_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerEnterAreaResponseMessage:
	func _init():
		var service
		
		__area_name = PBField.new("area_name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __area_name
		data[__area_name.tag] = service
		
		__success = PBField.new("success", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __success
		data[__success.tag] = service
		
		__reason = PBField.new("reason", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __reason
		data[__reason.tag] = service
		
	var data = {}
	
	var __area_name: PBField
	func has_area_name() -> bool:
		if __area_name.value != null:
			return true
		return false
	func get_area_name() -> String:
		return __area_name.value
	func clear_area_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__area_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_area_name(value : String) -> void:
		__area_name.value = value
	
	var __success: PBField
	func has_success() -> bool:
		if __success.value != null:
			return true
		return false
	func get_success() -> bool:
		return __success.value
	func clear_success() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_success(value : bool) -> void:
		__success.value = value
	
	var __reason: PBField
	func has_reason() -> bool:
		if __reason.value != null:
			return true
		return false
	func get_reason() -> String:
		return __reason.value
	func clear_reason() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__reason.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_reason(value : String) -> void:
		__reason.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerEnterAreaMessage:
	func _init():
		var service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service
		
		__y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service
		
	var data = {}
	
	var __username: PBField
	func has_username() -> bool:
		if __username.value != null:
			return true
		return false
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __x: PBField
	func has_x() -> bool:
		if __x.value != null:
			return true
		return false
	func get_x() -> float:
		return __x.value
	func clear_x() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_x(value : float) -> void:
		__x.value = value
	
	var __y: PBField
	func has_y() -> bool:
		if __y.value != null:
			return true
		return false
	func get_y() -> float:
		return __y.value
	func clear_y() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_y(value : float) -> void:
		__y.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerLeaveAreaMessage:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayerMoveMessage:
	func _init():
		var service
		
		__from_x = PBField.new("from_x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __from_x
		data[__from_x.tag] = service
		
		__from_y = PBField.new("from_y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __from_y
		data[__from_y.tag] = service
		
		__to_x = PBField.new("to_x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __to_x
		data[__to_x.tag] = service
		
		__to_y = PBField.new("to_y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __to_y
		data[__to_y.tag] = service
		
	var data = {}
	
	var __from_x: PBField
	func has_from_x() -> bool:
		if __from_x.value != null:
			return true
		return false
	func get_from_x() -> float:
		return __from_x.value
	func clear_from_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__from_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_from_x(value : float) -> void:
		__from_x.value = value
	
	var __from_y: PBField
	func has_from_y() -> bool:
		if __from_y.value != null:
			return true
		return false
	func get_from_y() -> float:
		return __from_y.value
	func clear_from_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__from_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_from_y(value : float) -> void:
		__from_y.value = value
	
	var __to_x: PBField
	func has_to_x() -> bool:
		if __to_x.value != null:
			return true
		return false
	func get_to_x() -> float:
		return __to_x.value
	func clear_to_x() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__to_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_to_x(value : float) -> void:
		__to_x.value = value
	
	var __to_y: PBField
	func has_to_y() -> bool:
		if __to_y.value != null:
			return true
		return false
	func get_to_y() -> float:
		return __to_y.value
	func clear_to_y() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__to_y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_to_y(value : float) -> void:
		__to_y.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ChatMessage:
	func _init():
		var service
		
		__content = PBField.new("content", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __content
		data[__content.tag] = service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__type = PBField.new("type", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __type
		data[__type.tag] = service
		
	var data = {}
	
	var __content: PBField
	func has_content() -> bool:
		if __content.value != null:
			return true
		return false
	func get_content() -> String:
		return __content.value
	func clear_content() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__content.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_content(value : String) -> void:
		__content.value = value
	
	var __username: PBField
	func has_username() -> bool:
		if __username.value != null:
			return true
		return false
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __type: PBField
	func has_type() -> bool:
		if __type.value != null:
			return true
		return false
	func get_type() -> int:
		return __type.value
	func clear_type() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_type(value : int) -> void:
		__type.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MailRequestMessage:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MailMessage:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__titles = PBField.new("titles", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __titles
		data[__titles.tag] = service
		
		__contents = PBField.new("contents", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __contents
		data[__contents.tag] = service
		
		__sender = PBField.new("sender", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __sender
		data[__sender.tag] = service
		
		var __items_default: Array[ItemMessage] = []
		__items = PBField.new("items", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 5, true, __items_default)
		service = PBServiceField.new()
		service.field = __items
		service.func_ref = Callable(self, "add_items")
		data[__items.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __titles: PBField
	func has_titles() -> bool:
		if __titles.value != null:
			return true
		return false
	func get_titles() -> String:
		return __titles.value
	func clear_titles() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__titles.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_titles(value : String) -> void:
		__titles.value = value
	
	var __contents: PBField
	func has_contents() -> bool:
		if __contents.value != null:
			return true
		return false
	func get_contents() -> String:
		return __contents.value
	func clear_contents() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__contents.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_contents(value : String) -> void:
		__contents.value = value
	
	var __sender: PBField
	func has_sender() -> bool:
		if __sender.value != null:
			return true
		return false
	func get_sender() -> String:
		return __sender.value
	func clear_sender() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__sender.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_sender(value : String) -> void:
		__sender.value = value
	
	var __items: PBField
	func get_items() -> Array[ItemMessage]:
		return __items.value
	func clear_items() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__items.value.clear()
	func add_items() -> ItemMessage:
		var element = ItemMessage.new()
		__items.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MailCollectMessage:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_id(value : int) -> void:
		__id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MailCollectResponseMessage:
	func _init():
		var service
		
		__success = PBField.new("success", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __success
		data[__success.tag] = service
		
		__reason = PBField.new("reason", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __reason
		data[__reason.tag] = service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
	var data = {}
	
	var __success: PBField
	func has_success() -> bool:
		if __success.value != null:
			return true
		return false
	func get_success() -> bool:
		return __success.value
	func clear_success() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_success(value : bool) -> void:
		__success.value = value
	
	var __reason: PBField
	func has_reason() -> bool:
		if __reason.value != null:
			return true
		return false
	func get_reason() -> String:
		return __reason.value
	func clear_reason() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__reason.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_reason(value : String) -> void:
		__reason.value = value
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_id(value : int) -> void:
		__id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class MailDeleteMessage:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_id(value : int) -> void:
		__id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ItemMessage:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__count = PBField.new("count", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __count: PBField
	func has_count() -> bool:
		if __count.value != null:
			return true
		return false
	func get_count() -> int:
		return __count.value
	func clear_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_count(value : int) -> void:
		__count.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class BagRequestMessage:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class BagMessage:
	func _init():
		var service
		
		var __id_default: Array[int] = []
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.REPEATED, 1, true, __id_default)
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		var __count_default: Array[int] = []
		__count = PBField.new("count", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 2, true, __count_default)
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
	var data = {}
	
	var __id: PBField
	func get_id() -> Array[int]:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value.clear()
	func add_id(value : int) -> void:
		__id.value.append(value)
	
	var __count: PBField
	func get_count() -> Array[int]:
		return __count.value
	func clear_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__count.value.clear()
	func add_count(value : int) -> void:
		__count.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AddBagItemMessage:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__count = PBField.new("count", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __count: PBField
	func has_count() -> bool:
		if __count.value != null:
			return true
		return false
	func get_count() -> int:
		return __count.value
	func clear_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_count(value : int) -> void:
		__count.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DeleteBagItemMessage:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__count = PBField.new("count", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __count: PBField
	func has_count() -> bool:
		if __count.value != null:
			return true
		return false
	func get_count() -> int:
		return __count.value
	func clear_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_count(value : int) -> void:
		__count.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UseBagItemRequestMessage:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__count = PBField.new("count", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __count: PBField
	func has_count() -> bool:
		if __count.value != null:
			return true
		return false
	func get_count() -> int:
		return __count.value
	func clear_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_count(value : int) -> void:
		__count.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UseBagItemResponseMessage:
	func _init():
		var service
		
		__success = PBField.new("success", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __success
		data[__success.tag] = service
		
		__reason = PBField.new("reason", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __reason
		data[__reason.tag] = service
		
	var data = {}
	
	var __success: PBField
	func has_success() -> bool:
		if __success.value != null:
			return true
		return false
	func get_success() -> bool:
		return __success.value
	func clear_success() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_success(value : bool) -> void:
		__success.value = value
	
	var __reason: PBField
	func has_reason() -> bool:
		if __reason.value != null:
			return true
		return false
	func get_reason() -> String:
		return __reason.value
	func clear_reason() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__reason.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_reason(value : String) -> void:
		__reason.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Packet:
	func _init():
		var service
		
		__uid = PBField.new("uid", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __uid
		data[__uid.tag] = service
		
		__login_request = PBField.new("login_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __login_request
		service.func_ref = Callable(self, "new_login_request")
		data[__login_request.tag] = service
		
		__register_request = PBField.new("register_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __register_request
		service.func_ref = Callable(self, "new_register_request")
		data[__register_request.tag] = service
		
		__ok_response = PBField.new("ok_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __ok_response
		service.func_ref = Callable(self, "new_ok_response")
		data[__ok_response.tag] = service
		
		__deny_response = PBField.new("deny_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __deny_response
		service.func_ref = Callable(self, "new_deny_response")
		data[__deny_response.tag] = service
		
		__login_success = PBField.new("login_success", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __login_success
		service.func_ref = Callable(self, "new_login_success")
		data[__login_success.tag] = service
		
		__player_enter = PBField.new("player_enter", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __player_enter
		service.func_ref = Callable(self, "new_player_enter")
		data[__player_enter.tag] = service
		
		__player_leave = PBField.new("player_leave", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __player_leave
		service.func_ref = Callable(self, "new_player_leave")
		data[__player_leave.tag] = service
		
		__player_movement = PBField.new("player_movement", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __player_movement
		service.func_ref = Callable(self, "new_player_movement")
		data[__player_movement.tag] = service
		
		__player_enter_request = PBField.new("player_enter_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __player_enter_request
		service.func_ref = Callable(self, "new_player_enter_request")
		data[__player_enter_request.tag] = service
		
		__chat = PBField.new("chat", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __chat
		service.func_ref = Callable(self, "new_chat")
		data[__chat.tag] = service
		
		__player_enter_area_response = PBField.new("player_enter_area_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __player_enter_area_response
		service.func_ref = Callable(self, "new_player_enter_area_response")
		data[__player_enter_area_response.tag] = service
		
		__mail = PBField.new("mail", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __mail
		service.func_ref = Callable(self, "new_mail")
		data[__mail.tag] = service
		
		__mail_request = PBField.new("mail_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __mail_request
		service.func_ref = Callable(self, "new_mail_request")
		data[__mail_request.tag] = service
		
		__mail_collect = PBField.new("mail_collect", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __mail_collect
		service.func_ref = Callable(self, "new_mail_collect")
		data[__mail_collect.tag] = service
		
		__mail_delete = PBField.new("mail_delete", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __mail_delete
		service.func_ref = Callable(self, "new_mail_delete")
		data[__mail_delete.tag] = service
		
		__mail_collect_response = PBField.new("mail_collect_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __mail_collect_response
		service.func_ref = Callable(self, "new_mail_collect_response")
		data[__mail_collect_response.tag] = service
		
		__bag_request = PBField.new("bag_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __bag_request
		service.func_ref = Callable(self, "new_bag_request")
		data[__bag_request.tag] = service
		
		__bag = PBField.new("bag", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __bag
		service.func_ref = Callable(self, "new_bag")
		data[__bag.tag] = service
		
		__add_bag_item = PBField.new("add_bag_item", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __add_bag_item
		service.func_ref = Callable(self, "new_add_bag_item")
		data[__add_bag_item.tag] = service
		
		__delete_bag_item = PBField.new("delete_bag_item", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __delete_bag_item
		service.func_ref = Callable(self, "new_delete_bag_item")
		data[__delete_bag_item.tag] = service
		
		__use_bag_item_request = PBField.new("use_bag_item_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __use_bag_item_request
		service.func_ref = Callable(self, "new_use_bag_item_request")
		data[__use_bag_item_request.tag] = service
		
		__use_bag_item_response = PBField.new("use_bag_item_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 23, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __use_bag_item_response
		service.func_ref = Callable(self, "new_use_bag_item_response")
		data[__use_bag_item_response.tag] = service
		
		__ui_packet = PBField.new("ui_packet", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __ui_packet
		service.func_ref = Callable(self, "new_ui_packet")
		data[__ui_packet.tag] = service
		
	var data = {}
	
	var __uid: PBField
	func has_uid() -> bool:
		if __uid.value != null:
			return true
		return false
	func get_uid() -> int:
		return __uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_uid(value : int) -> void:
		__uid.value = value
	
	var __login_request: PBField
	func has_login_request() -> bool:
		if __login_request.value != null:
			return true
		return false
	func get_login_request() -> LoginRequestMessage:
		return __login_request.value
	func clear_login_request() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_login_request() -> LoginRequestMessage:
		data[2].state = PB_SERVICE_STATE.FILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = LoginRequestMessage.new()
		return __login_request.value
	
	var __register_request: PBField
	func has_register_request() -> bool:
		if __register_request.value != null:
			return true
		return false
	func get_register_request() -> RegisterRequestMessage:
		return __register_request.value
	func clear_register_request() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_register_request() -> RegisterRequestMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		data[3].state = PB_SERVICE_STATE.FILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = RegisterRequestMessage.new()
		return __register_request.value
	
	var __ok_response: PBField
	func has_ok_response() -> bool:
		if __ok_response.value != null:
			return true
		return false
	func get_ok_response() -> OKResponseMessage:
		return __ok_response.value
	func clear_ok_response() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ok_response() -> OKResponseMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		data[4].state = PB_SERVICE_STATE.FILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = OKResponseMessage.new()
		return __ok_response.value
	
	var __deny_response: PBField
	func has_deny_response() -> bool:
		if __deny_response.value != null:
			return true
		return false
	func get_deny_response() -> DenyResponseMessage:
		return __deny_response.value
	func clear_deny_response() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_deny_response() -> DenyResponseMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		data[5].state = PB_SERVICE_STATE.FILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DenyResponseMessage.new()
		return __deny_response.value
	
	var __login_success: PBField
	func has_login_success() -> bool:
		if __login_success.value != null:
			return true
		return false
	func get_login_success() -> LoginSuccessMessage:
		return __login_success.value
	func clear_login_success() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_login_success() -> LoginSuccessMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		data[6].state = PB_SERVICE_STATE.FILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = LoginSuccessMessage.new()
		return __login_success.value
	
	var __player_enter: PBField
	func has_player_enter() -> bool:
		if __player_enter.value != null:
			return true
		return false
	func get_player_enter() -> PlayerEnterAreaMessage:
		return __player_enter.value
	func clear_player_enter() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_player_enter() -> PlayerEnterAreaMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		data[7].state = PB_SERVICE_STATE.FILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = PlayerEnterAreaMessage.new()
		return __player_enter.value
	
	var __player_leave: PBField
	func has_player_leave() -> bool:
		if __player_leave.value != null:
			return true
		return false
	func get_player_leave() -> PlayerLeaveAreaMessage:
		return __player_leave.value
	func clear_player_leave() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_player_leave() -> PlayerLeaveAreaMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		data[8].state = PB_SERVICE_STATE.FILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = PlayerLeaveAreaMessage.new()
		return __player_leave.value
	
	var __player_movement: PBField
	func has_player_movement() -> bool:
		if __player_movement.value != null:
			return true
		return false
	func get_player_movement() -> PlayerMoveMessage:
		return __player_movement.value
	func clear_player_movement() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_player_movement() -> PlayerMoveMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		data[9].state = PB_SERVICE_STATE.FILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = PlayerMoveMessage.new()
		return __player_movement.value
	
	var __player_enter_request: PBField
	func has_player_enter_request() -> bool:
		if __player_enter_request.value != null:
			return true
		return false
	func get_player_enter_request() -> PlayerEnterAreaRequestMessage:
		return __player_enter_request.value
	func clear_player_enter_request() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_player_enter_request() -> PlayerEnterAreaRequestMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		data[10].state = PB_SERVICE_STATE.FILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = PlayerEnterAreaRequestMessage.new()
		return __player_enter_request.value
	
	var __chat: PBField
	func has_chat() -> bool:
		if __chat.value != null:
			return true
		return false
	func get_chat() -> ChatMessage:
		return __chat.value
	func clear_chat() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_chat() -> ChatMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		data[11].state = PB_SERVICE_STATE.FILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = ChatMessage.new()
		return __chat.value
	
	var __player_enter_area_response: PBField
	func has_player_enter_area_response() -> bool:
		if __player_enter_area_response.value != null:
			return true
		return false
	func get_player_enter_area_response() -> PlayerEnterAreaResponseMessage:
		return __player_enter_area_response.value
	func clear_player_enter_area_response() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_player_enter_area_response() -> PlayerEnterAreaResponseMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		data[12].state = PB_SERVICE_STATE.FILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = PlayerEnterAreaResponseMessage.new()
		return __player_enter_area_response.value
	
	var __mail: PBField
	func has_mail() -> bool:
		if __mail.value != null:
			return true
		return false
	func get_mail() -> MailMessage:
		return __mail.value
	func clear_mail() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_mail() -> MailMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		data[13].state = PB_SERVICE_STATE.FILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = MailMessage.new()
		return __mail.value
	
	var __mail_request: PBField
	func has_mail_request() -> bool:
		if __mail_request.value != null:
			return true
		return false
	func get_mail_request() -> MailRequestMessage:
		return __mail_request.value
	func clear_mail_request() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_mail_request() -> MailRequestMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		data[14].state = PB_SERVICE_STATE.FILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = MailRequestMessage.new()
		return __mail_request.value
	
	var __mail_collect: PBField
	func has_mail_collect() -> bool:
		if __mail_collect.value != null:
			return true
		return false
	func get_mail_collect() -> MailCollectMessage:
		return __mail_collect.value
	func clear_mail_collect() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_mail_collect() -> MailCollectMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		data[15].state = PB_SERVICE_STATE.FILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = MailCollectMessage.new()
		return __mail_collect.value
	
	var __mail_delete: PBField
	func has_mail_delete() -> bool:
		if __mail_delete.value != null:
			return true
		return false
	func get_mail_delete() -> MailDeleteMessage:
		return __mail_delete.value
	func clear_mail_delete() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_mail_delete() -> MailDeleteMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		data[16].state = PB_SERVICE_STATE.FILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = MailDeleteMessage.new()
		return __mail_delete.value
	
	var __mail_collect_response: PBField
	func has_mail_collect_response() -> bool:
		if __mail_collect_response.value != null:
			return true
		return false
	func get_mail_collect_response() -> MailCollectResponseMessage:
		return __mail_collect_response.value
	func clear_mail_collect_response() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_mail_collect_response() -> MailCollectResponseMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		data[17].state = PB_SERVICE_STATE.FILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = MailCollectResponseMessage.new()
		return __mail_collect_response.value
	
	var __bag_request: PBField
	func has_bag_request() -> bool:
		if __bag_request.value != null:
			return true
		return false
	func get_bag_request() -> BagRequestMessage:
		return __bag_request.value
	func clear_bag_request() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_bag_request() -> BagRequestMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		data[18].state = PB_SERVICE_STATE.FILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = BagRequestMessage.new()
		return __bag_request.value
	
	var __bag: PBField
	func has_bag() -> bool:
		if __bag.value != null:
			return true
		return false
	func get_bag() -> BagMessage:
		return __bag.value
	func clear_bag() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_bag() -> BagMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		data[19].state = PB_SERVICE_STATE.FILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = BagMessage.new()
		return __bag.value
	
	var __add_bag_item: PBField
	func has_add_bag_item() -> bool:
		if __add_bag_item.value != null:
			return true
		return false
	func get_add_bag_item() -> AddBagItemMessage:
		return __add_bag_item.value
	func clear_add_bag_item() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_add_bag_item() -> AddBagItemMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		data[20].state = PB_SERVICE_STATE.FILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = AddBagItemMessage.new()
		return __add_bag_item.value
	
	var __delete_bag_item: PBField
	func has_delete_bag_item() -> bool:
		if __delete_bag_item.value != null:
			return true
		return false
	func get_delete_bag_item() -> DeleteBagItemMessage:
		return __delete_bag_item.value
	func clear_delete_bag_item() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_delete_bag_item() -> DeleteBagItemMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		data[21].state = PB_SERVICE_STATE.FILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DeleteBagItemMessage.new()
		return __delete_bag_item.value
	
	var __use_bag_item_request: PBField
	func has_use_bag_item_request() -> bool:
		if __use_bag_item_request.value != null:
			return true
		return false
	func get_use_bag_item_request() -> UseBagItemRequestMessage:
		return __use_bag_item_request.value
	func clear_use_bag_item_request() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_use_bag_item_request() -> UseBagItemRequestMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		data[22].state = PB_SERVICE_STATE.FILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = UseBagItemRequestMessage.new()
		return __use_bag_item_request.value
	
	var __use_bag_item_response: PBField
	func has_use_bag_item_response() -> bool:
		if __use_bag_item_response.value != null:
			return true
		return false
	func get_use_bag_item_response() -> UseBagItemResponseMessage:
		return __use_bag_item_response.value
	func clear_use_bag_item_response() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_use_bag_item_response() -> UseBagItemResponseMessage:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		data[23].state = PB_SERVICE_STATE.FILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = UseBagItemResponseMessage.new()
		return __use_bag_item_response.value
	
	var __ui_packet: PBField
	func has_ui_packet() -> bool:
		if __ui_packet.value != null:
			return true
		return false
	func get_ui_packet() -> UiPacket:
		return __ui_packet.value
	func clear_ui_packet() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__ui_packet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ui_packet() -> UiPacket:
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_success.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__player_enter.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__player_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__player_movement.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__player_enter_area_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__mail.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__mail_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__mail_delete.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__mail_collect_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__bag_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__bag.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__add_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__delete_bag_item.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__use_bag_item_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[23].state = PB_SERVICE_STATE.UNFILLED
		data[24].state = PB_SERVICE_STATE.FILLED
		__ui_packet.value = UiPacket.new()
		return __ui_packet.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UiPacket:
	func _init():
		var service
		
		__open_ui = PBField.new("open_ui", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __open_ui
		service.func_ref = Callable(self, "new_open_ui")
		data[__open_ui.tag] = service
		
		__initial_pet_request = PBField.new("initial_pet_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __initial_pet_request
		service.func_ref = Callable(self, "new_initial_pet_request")
		data[__initial_pet_request.tag] = service
		
	var data = {}
	
	var __open_ui: PBField
	func has_open_ui() -> bool:
		if __open_ui.value != null:
			return true
		return false
	func get_open_ui() -> OpenUIMessage:
		return __open_ui.value
	func clear_open_ui() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__open_ui.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_open_ui() -> OpenUIMessage:
		data[1].state = PB_SERVICE_STATE.FILLED
		__initial_pet_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__open_ui.value = OpenUIMessage.new()
		return __open_ui.value
	
	var __initial_pet_request: PBField
	func has_initial_pet_request() -> bool:
		if __initial_pet_request.value != null:
			return true
		return false
	func get_initial_pet_request() -> InitialPetRequestMessage:
		return __initial_pet_request.value
	func clear_initial_pet_request() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__initial_pet_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_initial_pet_request() -> InitialPetRequestMessage:
		__open_ui.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		data[2].state = PB_SERVICE_STATE.FILLED
		__initial_pet_request.value = InitialPetRequestMessage.new()
		return __initial_pet_request.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class OpenUIMessage:
	func _init():
		var service
		
		__path = PBField.new("path", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __path
		data[__path.tag] = service
		
	var data = {}
	
	var __path: PBField
	func has_path() -> bool:
		if __path.value != null:
			return true
		return false
	func get_path() -> String:
		return __path.value
	func clear_path() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__path.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_path(value : String) -> void:
		__path.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InitialPetRequestMessage:
	func _init():
		var service
		
		__request_id = PBField.new("request_id", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __request_id
		data[__request_id.tag] = service
		
	var data = {}
	
	var __request_id: PBField
	func has_request_id() -> bool:
		if __request_id.value != null:
			return true
		return false
	func get_request_id() -> int:
		return __request_id.value
	func clear_request_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__request_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_request_id(value : int) -> void:
		__request_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
