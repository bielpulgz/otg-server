#ifndef FS_SHADERS_H
#define FS_SHADERS_H

#include <string>
#include <vector>

struct Shader
{
    Shader(uint8_t id, std::string name, bool premium) :
        id(id), name(std::move(name)), premium(premium) {}

    uint8_t id;
    std::string name;
    bool premium;
};

class Shaders
{
public:
    bool reload();
    bool loadFromXml();
    Shader* getShaderByID(uint8_t id);
    Shader* getShaderByName(const std::string& name);

    const std::vector<Shader>& getShaders() const {
        return shaders;
    }

private:
    std::vector<Shader> shaders;
};

#endif