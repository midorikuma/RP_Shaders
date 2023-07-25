OBJFileName = 'steve.obj'
TEXTUREFileName = 'steve.png'

OUTPUTFileName = 'skin.png'
UserName = 'Please enter your minecraft user name'


file = open(OBJFileName,encoding='utf-8')
vs=[]
vt=[]
fvs=[]
fvt=[]
for line in file.readlines():
    linechar = line.split()
    type = linechar[0]
    values = linechar[1:]

    if type=='v':
        vs.extend(values)
    if type=='vt':
        vt.extend(values)
    if type=='f':
        fvs.extend([val.split('/')[0] for val in values])
        fvt.extend([val.split('/')[1] for val in values])

valuesvt = [float(v) for v in vt]
fvs = [int(v) for v in fvs]
valuesfvt = [int(v) for v in fvt]
vts = []
for i in range(len(valuesfvt)):
    for j in range(2):
        vts.append(valuesvt[(valuesfvt[i]-1)*2+j])
vs = [float(v) for v in vs]

lfvs = len(fvs)
lvts = len(vts)
lvs = len(vs)


from PIL import Image

u=255
out = Image.new('RGBA', (64, 64), (u,u,u,u))

#uv
tex = Image.open(TEXTUREFileName)
tex = tex.resize((32, 32), Image.NEAREST)
for i in range(32):
    for j in range(32):
        out.putpixel((32+i,j), tex.getpixel((i, j)))

logo = [
        [1,1,1,1,0,1,1,0,1,1,0,1,0,0,1],
        [1,0,0,0,0,1,0,1,0,1,0,1,1,1,1],
        [1,0,0,0,0,1,0,1,0,1,0,1,0,0,1],
        [1,1,1,1,0,1,0,1,0,1,0,1,0,0,1]
        ]
for i in range(4):
    for j in range(15):
        if logo[i][j]==1:
            out.putpixel((j,i), (112,134,156,255))
            
#main data
#line0
#version
out.putpixel((16,0), (12,34,56,78))
#name
#line1
#poly count
pc = int(int(lfvs)/3)
#vertices count
vc = int(int(lvs)/3)
vcl=0
if 255<vc:
    vc-=255
    vcl=255
out.putpixel((16,1), (pc,vc,vcl,255))
#line2
#frame count

#obj data
#fv
t=[0]*3
for i in range(int(int(lfvs)/3)):
    if i%8==0:
        a=[0]*3
    for j in range(3):
        t[j] = int(fvs[i*3+j])
        if 255<t[j]:
            t[j]-=255
            a[j]+=2**(i%8)
    out.putpixel((i%32,4+int(i/32)), (t[0],t[1],t[2],255))
    out.putpixel((int(i/8),12), (a[0],a[1],a[2],255))
#fvt
t=[0]*3
vts.extend([0, 0])
for i in range(int(int(lvts)/6)):
    for j in range(3):
        t[j] = int(vts[i*6+j*2]*255)
    k=i*2
    out.putpixel((k%32,13+int(k/32)), (t[0],t[1],t[2],255))
    for j in range(3):
        t[j] = int(vts[i*6+j*2+1]*255)
    k=i*2+1
    out.putpixel((k%32,13+int(k/32)), (t[0],t[1],t[2],255))
#v
t=[0]*3
for i in range(int(int(lvs)/3)):
    if i%8==0:
        a=[0]*3
    for j in range(3):
        t[j] = int(vs[i*3+j]*255)
        if t[j]<0:
            t[j]*=-1
            a[j]+=2**(i%8)
    out.putpixel((16+i%32,48+int(i/32)), (t[0],t[1],t[2],255))
    out.putpixel((int(i/8)%32,29+int(i/32/8)), (a[0],a[1],a[2],255))


out.save(OUTPUTFileName)
print("Skin image output is complete. Please change the skin.")


import os,re,urllib.request,json,base64
os.system('PAUSE')

url = 'https://api.mojang.com/users/profiles/minecraft/'+UserName
response = urllib.request.urlopen(url)
content = json.loads(response.read().decode('utf8'))
uuid = content['id']

hexArray = re.split('(........)', uuid)[1::2]
intArray = [int(v, 16) for v in hexArray]
intArray =  [v-2147483648*2 if 2147483647<v else v for v in intArray]
strArray = [str(v) for v in intArray]

url = 'https://sessionserver.mojang.com/session/minecraft/profile/'+uuid
response = urllib.request.urlopen(url)
content = json.loads(response.read().decode('utf8'))
value = content['properties'][0]['value']

content = json.loads(base64.b64decode(value).decode())
value = {k: v for k, v in content.items() if k == 'textures'}
value = base64.b64encode(str(value).encode())
value = re.search(r'\'(.+)\'',str(value)).group(1)

id = ','.join(strArray)
command = "give @p minecraft:player_head{SkullOwner:{Id:[I;"+id+"],Properties:{textures:[{Value:\""+value+"\"}]}}}"

open('CMHlist.mcfunction', 'a+', encoding='UTF-8')
CMHlist = open('CMHlist.mcfunction', 'r', encoding='UTF-8').readlines()
if not (command+'\n' in CMHlist):
    with open('CMHlist.mcfunction', 'a', encoding='UTF-8') as f:
        print('###'+OBJFileName, file=f)
        print(command, file=f)
print(command)