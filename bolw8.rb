require 'sinatra'
require 'cgi'
require 'nokogiri'
require 'pry'
require 'fileutils'

require_relative 'item'

use Rack::Auth::Basic, "Restricted Area" do |username, password|
	F='creds'

	if File.exist?(F)
		creds={}
		File.open('./creds') do |fp|
			fp.each do |line|
				nombre,pass = line.chomp.split(":")
				creds[nombre]=pass
			end
		end

		creds[username]==password
	else
		abort("Falta el archivo de credenciales")
	end
end

set :show_exceptions, false
set :bind, '0.0.0.0'
set :port, 1212
set :items, Hash.new
set :currentitem, nil
set :idboletin, ''
set :docen, ''
set :doces, ''
set :boletin, ''
set :fechaes, ''
set :fechaen, ''
set :tags, nil
set	:noticias, Array.new
set	:documentos, Array.new
set	:eventos, Array.new
set	:reflexiones, Array.new
set :equipos, Array.new
set :DirHTML, './public/html/'
set :DirXML, './public/xml/'
set :erro, ''
set :notsel, nil
set :docsel, nil
set :evesel, nil
set :refsel, nil
set :equsel, nil
set :nreflex, 0
set :cargado, nil
set :Idiomas, ['EN','ES','PO','FR','GE']

Meses=['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre']
Months=['January','February','March','April','May','June','July','August','September','October','November','December']


$showExceptions = Sinatra::ShowExceptions.new(self)

# Error handler. Ante una excepción salva los XML en el directorio XML/error
error do
	fname=settings.DirXML+"error/#{settings.boletin}-en.xml"
	genXML(fname,'en')
	fname=settings.DirXML+"error/#{settings.boletin}.xml"
	genXML(fname,'es')
	@error=env['sinatra.error']
	$showExceptions.pretty(env, @error)
end

def genXML(fname,idioma)
		if File.file?(fname)
			FileUtils.cp(fname,settings.DirXML+'bkp/')
		end
		f=File.open(fname,'w')
		if idioma=='en'
			f.write("#{builder :xml, :locals => {:items => settings.items, :id => settings.idboletin, :fecha => settings.fechaen, :listas => [settings.noticias,settings.documentos,settings.eventos,settings.reflexiones,settings.equipos] , :lan =>'en'}}")
		else
			f.write("#{builder :xml, :locals => {:items => settings.items, :id => settings.idboletin, :fecha => settings.fechaes, :listas => [settings.noticias,settings.documentos,settings.eventos,settings.reflexiones,settings.equipos], :lan =>'es'}}")
		end
		f.close()
end

def genHTML(fname,idioma)
	f=File.open(fname,'w')
	if idioma=='en'
		f.write("#{erb :html, :locals => {:items => settings.items, :id => settings.idboletin, :fecha => settings.fechaen, :listas => [settings.noticias,settings.documentos,settings.eventos,settings.reflexiones,settings.equipos] , :lan =>'en'}}")
	else
		f.write("#{erb :html, :locals => {:items => settings.items, :id => settings.idboletin, :fecha => settings.fechaes, :listas => [settings.noticias,settings.documentos,settings.eventos,settings.reflexiones,settings.equipos] , :lan =>'es'}}")
	end
	f.close
end

def htmlitem(item,lan)
	if (!item.nil?)
		if (lan=='es')
			tit=item.titulo
			tex=item.texto
			lin=item.enlace
			idioma=item.len
		else
			tit=item.title
			tex=item.text
			lin=item.link
			idioma=item.lan
		end
		
		if (item.destacado=="1")
			t="<div>
			<strong><font size=\"4\" color=\"#B40404\">#{tit}</font></strong></div>
			<div>#{tex}</div>"
		else
			t="<div>
			<strong>#{tit}</strong></div>
			<div>#{tex}</div>"
		end
		
		if (lan=='es')
			u="<div><a href=\"#{lin}\" target=\"_self\">Enlace</a>"
		else
			u="<div><a href=\"#{lin}\" target=\"_self\">Link</a>"
		end
		
		if !idioma.empty?
			u=u+" [#{idioma}]</div><div>&nbsp;</div>"
		else
			u=u+"</div><div>&nbsp;</div>"
		end

		# Hack para evitar entradas de equipos de conocimiento en boletin inglés
		if (lan=='en' && item.tipo=='equipo')
			salida=''
		else
			salida=t+u
		end
	else
		salida=''
	end
	return salida
end

def up(lista,i)
	if (i>0)
		a=lista[i-1]
		lista[i-1]=lista[i]
		lista[i]=a
	end
	lista
end

def down(lista,i)
	if (i<lista.length-1)
		a=lista[i+1]
		lista[i+1]=lista[i]
		lista[i]=a
	end
	lista
end

def carga_tags
	filenames=Dir[settings.DirXML+"*-en.xml"]
	tags=Array.new
	filenames.each do |n|
		f=File.open(n,'r')
		doc=Nokogiri::XML(f)
		stags=doc.xpath("//tag")
		stags.each do |s|
			ta=s.text.split(',')
			ta.each do |t|
				tags.push(t.strip)
			end
		end
		f.close
	end
	settings.tags=Hash.new 0

	tags.sort_by!{|w| w.downcase}
	tags.each do |t|
		if !t.empty?
			settings.tags[t]+=1
		end
	end
end

def carga_boletin
	fname=settings.DirXML+"#{settings.boletin}-en.xml"

	f=File.open(fname)
	settings.docen=Nokogiri::XML(f)
	f.close
	fname=settings.DirXML+"#{settings.boletin}.xml"
	f=File.open(fname)
	settings.doces=Nokogiri::XML(f)
	f.close
	
	settings.idboletin=settings.doces.xpath("//id").text
	settings.fechaes=settings.doces.xpath("//fecha").text
	settings.fechaen=settings.docen.xpath("//fecha").text

	nodoses=settings.doces.xpath("//item")
	nodosen=settings.docen.xpath("//item")

	nodos=nodoses.zip(nodosen)

	its=Hash.new

	nodos.each do |nodoes,nodoen|
		item=Item.new()
		item.setfromxml(nodoes,nodoen)
		# Genera token aleatorio
		h=rand(36**8).to_s(36)
		its[h]=item
		if item.tipo=="reflexion"
			settings.nreflex=settings.nreflex+1
		end
		#settings.items.push(item)
	end
	# items contiene los items cargados de los XML es y en
	its
end

get '/' do

	settings.noticias=nil
	settings.documentos=nil
	settings.eventos=nil
	settings.equipos=nil
	settings.reflexiones=nil
	
	settings.noticias=Array.new
	settings.documentos=Array.new
	settings.eventos=Array.new
	settings.equipos=Array.new
	settings.reflexiones=Array.new
	
	settings.currentitem=nil
	settings.nreflex=0
	
	erb :index
end


get '/cargaboletin' do
	carga_tags
	settings.nreflex=0
	settings.notsel=nil
	settings.docsel=nil
	settings.evesel=nil
	settings.equsel=nil
	settings.refsel=nil
	erb :cargaboletin
end

post '/cargaboletin' do
	settings.boletin=params[:boletin]

	settings.items=nil
	
	settings.noticias=nil
	settings.documentos=nil
	settings.eventos=nil
	settings.equipos=nil
	settings.reflexiones=nil
	
	settings.noticias=Array.new
	settings.documentos=Array.new
	settings.eventos=Array.new
	settings.equipos=Array.new
	settings.reflexiones=Array.new
	
	settings.items=carga_boletin

	redirect '/item'
end

get '/item' do
	erb :item, :locals => {:items => settings.items}
end

post '/item' do

	case (params[:action])
	when 'OK'
		titulo=params[:titulo]
		title=params[:title]
		texto=params[:texto]
		text=params[:text]	
		enlace=params[:enlace]	
		link=params[:link]	
		tipo=params[:tipo]
		tags=params[:tags]
		lan=params[:lan]
		len=params[:len]
		destacado=params[:destacado]
		
		#idioma="EN"
		
		if destacado=="on"
			destacado="1"
		else
			destacado="0"
		end
		
		if (tipo!='reflexion')
			if link.empty?
				link=enlace
				lan=len
			end
			if enlace.empty?
				enlace=link
				len=lan
			end
			if titulo.empty?
				titulo=title
			end
			if title.empty?
				title=titulo
			end
		else # Es reflexion
			settings.nreflex=settings.nreflex+1
			titulo="Reflexion #{settings.nreflex}"
			title=titulo
		end

		if !settings.cargado.nil?
			# Estamos editando
			# CurrentItem se establecio al cargar

			settings.currentitem=Item.new
			settings.currentitem.setall(titulo,title,texto,text,enlace,link,tipo,tags,lan,len,destacado)
			# Comprobaciones (redirigen a /item con currentitem establecido
			if (tipo!='reflexion')
				if (link.empty? && enlace.empty?)
					settings.erro="Debes completar el campo Enlace/Link"
					redirect '/item'
				end
			end


			settings.items[settings.cargado]=settings.currentitem
			# Anulamos currentitem antes de redirigir
			settings.currentitem=nil
			settings.cargado=nil
			redirect '/item'
		
		else
			# Nuevo elemento
			
			settings.currentitem=Item.new
			settings.currentitem.setall(titulo,title,texto,text,enlace,link,tipo,tags,lan,len,destacado)
			
			# Comprobaciones (redirigen a /item con currenitem establecido
			if (tipo!='reflexion')
				if (link.empty? && enlace.empty?)
					settings.erro="Debes completar el campo Enlace/Link"
					redirect '/item'
				end
			end
			
			# Metemos en la lista de items
			h=rand(36**8).to_s(36)
			settings.items[h]=settings.currentitem
			# Anulamos currentitem antes de redirigir
			settings.currentitem=nil
			redirect '/item'
		end

	when 'Carga'
		t=''
		if !params[:noticias].nil?
			t=params[:noticias]
		elsif !params[:documentos].nil?
			t=params[:documentos]
		elsif !params[:eventos].nil?
			t=params[:eventos]
		elsif !params[:equipos].nil?
			t=params[:equipos]
		else !params[:reflexiones].nil?
			t=params[:reflexiones]
		end
		
		settings.currentitem=settings.items[t]
		settings.cargado=t
		redirect '/item'

	when 'Terminar'
		fname=settings.DirXML+"#{settings.boletin}-en.xml"
		genXML(fname,'en')	
		fname=settings.DirXML+"#{settings.boletin}.xml"
		genXML(fname,'es')
		
		settings.fechaen =~ /(\w+) (\d+)\, (\d+)/
		
		dia=$2.rjust(2,'0')
		mes=(Months.index($1)+1).to_s.rjust(2,'0')

		fecha=$3+mes+dia

		fnamees="Boletin-#{fecha}.html"
		genHTML(settings.DirHTML+fnamees,'es')

		fnameen="Boletin-#{fecha}-en.html"
		genHTML(settings.DirHTML+fnameen,'en')

		redirect '/descargahtml'

	when 'Copiar Elementos'
		redirect '/copiar'

	when 'notup'
		t=params[:noticias]
		i=settings.noticias.index(t)
		if (!i.nil?)
			settings.noticias=up(settings.noticias,i)
			i==0 ? settings.notsel=0 : settings.notsel=i-1
		end
		redirect '/item'
	when 'notdown'
		t=params[:noticias]
		i=settings.noticias.index(t)
		if (!i.nil?)
			settings.noticias=down(settings.noticias,i)
			i==settings.noticias.length-1 ? settings.notsel=i : settings.notsel=i+1
		end
		redirect '/item'
		when 'docup'
		t=params[:documentos]
		i=settings.documentos.index(t)
		if (!i.nil?)		
			settings.documentos=up(settings.documentos,i)
			i==0 ? settings.docsel=0 : settings.docsel=i-1
		end
		redirect '/item'
	when 'docdown'
		t=params[:documentos]
		i=settings.documentos.index(t)
		if (!i.nil?)		
			settings.documentos=down(settings.documentos,i)
			i==settings.documentos.length-1 ? settings.docsel=i : settings.docsel=i+1
		end
		redirect '/item'
	when 'eveup'
		t=params[:eventos]
		i=settings.eventos.index(t)
		if (!i.nil?)		
			settings.eventos=up(settings.eventos,i)
			i==0 ? settings.evesel=0 : settings.evesel=i-1
		end
		redirect '/item'
	when 'evedown'
		t=params[:eventos]
		i=settings.eventos.index(t)
		if (!i.nil?)		
			settings.eventos=down(settings.eventos,i)
			i==settings.eventos.length-1 ? settings.evesel=i : settings.evesel=i+1
		end
		redirect '/item'
	when 'equup'
		t=params[:equipos]
		i=settings.equipos.index(t)
		if (!i.nil?)		
			settings.equipos=up(settings.equipos,i)
			i==0 ? settings.equsel=0 : settings.equsel=i-1
		end
		redirect '/item'
	when 'equdown'
		t=params[:equipos]
		i=settings.equipos.index(t)
		if (!i.nil?)		
			settings.equipos=down(settings.equipos,i)
			i==settings.equipos.length-1 ? settings.equsel=i : settings.equsel=i+1
		end
		redirect '/item'
	when 'refup'
		t=params[:reflexiones]
		i=settings.reflexiones.index(t)
		if (!i.nil?)				
			settings.reflexiones=up(settings.reflexiones,i)
			i==0 ? settings.refsel=0 : settings.refsel=i-1
		end
		redirect '/item'
	when 'refdown'
		t=params[:reflexiones]
		i=settings.reflexiones.index(t)
		if (!i.nil?)				
			settings.reflexiones=down(settings.reflexiones,i)
			i==settings.reflexiones.length-1 ? settings.refsel=i : settings.refsel=i+1
		end
		redirect '/item'
	end

end

get '/nuevoboletin' do
	settings.noticias=nil
	settings.documentos=nil
	settings.eventos=nil
	settings.equipos=nil
	settings.reflexiones=nil
	settings.nreflex=0
	
	settings.noticias=Array.new
	settings.documentos=Array.new
	settings.eventos=Array.new
	settings.equipos=Array.new
	settings.reflexiones=Array.new

	settings.items=nil
	settings.items=Hash.new
	
	erb :nuevoboletin
end

post '/nuevoboletin' do
	
	settings.idboletin=params[:id]
	settings.boletin="boletin"+params[:id]
	settings.fechaes=params[:dia]+" de "+Meses[params[:mes].to_i-1]+" de "+params[:ano]
	settings.fechaen=Months[params[:mes].to_i-1]+" "+params[:dia]+", "+params[:ano]
	
	redirect '/item'
end

get '/copiar' do
	erb :copiar
end

post '/copiar' do

	origitems=settings.items.dup
	accion=params[:action]
	if (accion=='ANuevo')
	
		filenames=Dir[settings.DirXML+"*.xml"]
		h=filenames.sort_by { |x| x[/\d+/].to_i }
		h.last  =~ /.*boletin(\d+)/
		id=$1.to_i+1
		Orig=Date.new(2013,6,3)
		actual=Orig+((id-1)*7)
		
		settings.idboletin=id
		settings.boletin="boletin#{id}"

		settings.fechaes="#{actual.day} de #{Meses[actual.month-1]} de #{actual.year}"
		settings.fechaen="#{Months[actual.month-1]} #{actual.day}, #{actual.year}"
	
		settings.items=nil
		settings.items=Hash.new
		settings.nreflex=0
	
	else
		settings.boletin=params[:boletin]

		# Meh
		settings.items=nil
		settings.items=Hash.new
		settings.items=carga_boletin
	
		if (settings.boletin.nil?)
			settings.erro="Debes seleccionar un boletin de destino"
			redirect '/copiar'
		end
	end
	
		settings.noticias=[]
		settings.documentos=[]
		settings.eventos=[]
		settings.equipos=[]
		settings.reflexiones=[]
		
		
	
		listas=[params[:noticias],params[:documentos],params[:eventos],params[:reflexiones],params[:equipos]]

			listas.each do |t|
				if !t.nil?
					t.each do |e|
						elem=origitems[e]
						settings.items[e]=elem
					end
				end
			end
	
	redirect '/item'
end

get '/descargaxml' do
	erb :descargaxml
end

get '/descargahtml' do
	erb :descargahtml
end

get '/download/:filename' do |filename|
	filename =~ /\.(.+)$/
	path='./public/'
	if ($1=="xml")
		path+="xml/"
	else
		path+="html/"
	end
  	send_file path+"#{filename}", :filename => filename, :type => 'Application/octet-stream'
end

get '/upload' do
	erb :upload
end

post '/upload' do
	fname=params[:myfile]

	if fname.length!=2
		settings.erro=("Debes seleccionar dos archivos")
		redirect '/upload'
	end
	f1=fname[0][:filename]
	f2=fname[1][:filename]
	f1 =~ /.+(\d+).+/
	n1=$1

	f2 =~ /.+(\d+).+/
	n2=$1
	if (n1!=n2)
		settings.erro=("Los XML deben pertenecer al mismo n&uacute;mero de bolet&iacute;n")
		redirect '/upload'
	end	


	xsd=Nokogiri::XML::Schema(File.read("./boletin.xsd"))
	fname.each do |fn|
		
		File.open('./public/xml/'+fn[:filename],"w") do |f|
			f.write(fn[:tempfile].read)
		end
	
		doc=Nokogiri::XML(File.read('./public/xml/'+fn[:filename]))
		#binding.pry
		#doc=Nokogiri::XML(fn[:tempfile].read)
		a=xsd.validate(doc)
		if !a.empty?
			t="#{fn[:filename]} Linea #{a[0].line}: #{a[0].message}"
			settings.erro=t
			redirect '/upload'
		end

	end
	redirect '/'
end

get '/historico' do
	erb :historico
end

post '/historico' do

	its=Hash.new 
	listas=Hash.new

	case (params[:action])
	when 'NotES'
		tipo='noticia'
		lan='es'
	when 'NotEN'
		tipo='noticia'
		lan='en'
	when 'DocES'
		tipo='documento'
		lan='es'
	when 'DocEN'
		tipo='documento'
		lan='en'
	when 'EveES'
		tipo='evento'
		lan='es'
	when 'EveEN'
		tipo='evento'
		lan='en'
	when 'RefES'
		tipo='reflexion'
		lan='es'
	when 'RefEN'
		tipo='reflexion'
		lan='en'
	when 'Equ'
		tipo='equipo'
		lan='es'
	end
	
	filenames=Dir[settings.DirXML+"*.xml"]
	filenames.sort!
	filenames.each do |f|
		lista=nil
		lista=Array.new

		if f=~ /.*boletin(\d+)\.xml/
			nombre="boletin"+$1

			fname=settings.DirXML+nombre+"-en.xml"
			f=File.open(fname)
			docen=Nokogiri::XML(f)
			f.close
			fname=settings.DirXML+nombre+".xml"
			f=File.open(fname)
			doces=Nokogiri::XML(f)
			f.close

			idboletin=doces.xpath("//id").text
			fechaes=doces.xpath("//fecha").text
			fechaen=docen.xpath("//fecha").text

			nodoses=doces.xpath("//item")
			nodosen=docen.xpath("//item")
			
			nodos=nodoses.zip(nodosen)
			nodos.each do |nodoes,nodoen|
				t=(nodoes/'./tipo').text
				if (t==tipo)
					item=nil		
					item=Item.new()
					item.setfromxml(nodoes,nodoen)
					lista.push(item)
				end
			end
			listas[fechaes]=lista
		else
			next
		end
	end
			
	"#{erb :hist, :locals => {:listas => listas, :tipo => tipo, :lan => lan}}"

end