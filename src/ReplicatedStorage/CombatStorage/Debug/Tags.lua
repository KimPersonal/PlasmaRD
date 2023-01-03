local Tags = {}
Tags._tags = {}

function Tags.newTag(tag)
	if Tags._tags[tag] == nil then
		Tags._tags[tag] = true
	end
end

function Tags.set(tag, value)
	assert(Tags._tags[tag] ~= nil, "unknown debug tag")
	assert(typeof(value) == "boolean", "tag value must be a boolean")
	Tags._tags[tag] = value
end

function Tags.get(tag)
	if tag then
		local value = Tags._tags[tag]
		assert(value ~= nil, "unknown debug tag")
		return value
	end
end

return Tags