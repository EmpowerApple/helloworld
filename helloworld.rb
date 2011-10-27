require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'

#DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/corkboard.sqlite3")
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://helloworld.db')

class Note
	include DataMapper::Resource
	
	property :id, Serial
	property :subject, Text, :required => true
	property :content, Text, :required => true
	property :created_at, Time
	property :updated_at, Time
	
	def to_json(*a)
		{
			'subject' => self.subject,
			'content' => self.content,
			'date' => self.updated_at.to_i
		}.to_json(*a)
	end
end

DataMapper.finalize
Note.auto_upgrade!


get '/' do
	'Hello Roger'
end


get '/note/:id' do
	puts "*** get note number #{params[:id]}"
	note = Note.get(params[:id])
	if note.nil? then
		status 404
	else
		status 200
		body(note.to_json)
	end
end

delete '/note/:id' do
	puts "*** delete note number #{params[:id]}"
	note = Note.get(params[:id])
	if note.nil? then
		status 404
	else
		if note.destroy then
			status 200
		else
			status 500
		end 
	end 
end 

put '/note' do
	data = JSON.parse(request.body.string)
	if data.nil? or !data.has_key?('subject') or !data.has_key?('content') then
		status = 400
	else
		note = Note.create(
							:subject=>data['subject'],
							:content=>data['content'],
							:created_at=>Time.now,
							:updated_at=>Time.now
							)
		note.save
		status 200
		puts "*** put a new note @" + note.id.to_s
		body(note.id.to_s)
	end
end

post '/note/:id' do
	puts "*** update note number #{params[:id]}"
	data = JSON.parse(request.body.string)
	
	if data.nil? then
		status = 400
	else
		puts ""
		note = Note.get(params[:id])
		if note.nil? then
			status 404
		else
			updated = false
			%w(subject content).each do |k|
				if data.hasKey?(k)
					note[k] = data[k]
					updated = true
				end
			end
			
			if updated then
				note['updated_at'] = Time.now
				if !note.save then
					status 500
				else
				end
			end
		end
	end
end
